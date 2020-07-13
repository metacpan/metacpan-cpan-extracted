package OpenTracing::Integration::RedisDB;
# ABSTRACT: OpenTracing APM support for RedisDB-based database interaction

use strict;
use warnings;

our $VERSION = '0.001';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Integration::RedisDB - support L<RedisDB> tracing

=head1 SYNOPSIS

 use OpenTracing::Integration qw(RedisDB);
 my $redis = RedisDB->new;
 $redis->get('some_key');

=head1 DESCRIPTION

See L<OpenTracing::Integration> for more details.

=cut

use Syntax::Keyword::Try;
use Role::Tiny::With;
use Class::Method::Modifiers qw(install_modifier);

use OpenTracing::DSL qw(:v1);

with qw(OpenTracing::Integration);

my $loaded;

sub load {
    my ($class, $load_deps) = @_;
    return unless $load_deps or RedisDB->can('new');

    unless($loaded++) {
        require RedisDB;
        install_modifier q{RedisDB}, around => send_command => sub {
            my ($code, $redis, $cmd, @rest) = @_;
            return trace {
                my ($span) = @_;
                try {
                    $span->tag(
                        'component'       => 'RedisDB',
                        'span.kind'       => 'client',
                        'db.operation'    => 'prepare',
                        'db.statement'    => join(' ', $cmd // (), @rest),
                        'db.type'         => 'redis',
                    );
                    return $redis->$code($cmd, @rest);
                } catch {
                    my $err = $@;
                    $span->tag(
                        error => 1,
                    );
                    die $@;
                }
            } operation_name => 'redis: ' . ($cmd // 'unknown');
        };
    }
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< TEAM@cpan.org >>

=head1 LICENSE

Copyright Tom Molesworth 2020. Licensed under the same terms as Perl itself.

