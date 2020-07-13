package OpenTracing::Integration::DBI;
# ABSTRACT: OpenTracing APM support for DBI-based database interaction

use strict;
use warnings;

our $VERSION = '0.001';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Integration::DBI - support L<DBI> tracing

=head1 SYNOPSIS

 use OpenTracing::Integration qw(DBI);
 my $dbh = DBI->connect(...);
 $dbh->selectall_arrayref(qw{select * from information_schema.tables});

=head1 DESCRIPTION

See L<OpenTracing::Integration> for more details.

=cut

use Syntax::Keyword::Try;
use Role::Tiny::With;
use Class::Method::Modifiers qw(install_modifier);

use OpenTracing::DSL qw(:v1);

with qw(OpenTracing::Integration);

my $loaded;

sub type_from_sql {
    my ($class, $sql) = @_;
    my ($type) = $sql =~ /\b(insert|select|update|delete|truncate\s+[a-z]+|copy\s+[a-z]+|show|vacuum|alter\s+[a-z]+|create\s+[a-z]+|drop\s+[a-z]+)\b/i;
    return $type;
}

sub load {
    my ($class, $load_deps) = @_;
    return unless $load_deps or DBI->can('connect');

    unless($loaded++) {
        require DBI;
        install_modifier q{DBI::db}, around => prepare => sub {
            my ($code, $dbh, $sql, @rest) = @_;
            my $type = $class->type_from_sql($sql);
            return trace {
                my ($span) = @_;
                try {
                    $span->tag(
                        'component'       => 'DBI',
                        'span.kind'       => 'client',
                        'db.operation'    => 'prepare',
                        'db.statement'    => $sql,
                        'db.type'         => 'sql',
                        (defined $dbh->{Name} ? ('db.instance'         => $dbh->{Name}) : ()),
                        (defined $dbh->{Username} ? ('db.user'         => $dbh->{Username}) : ()),
                    );
                    return $dbh->$code($sql, @rest);
                } catch {
                    my $err = $@;
                    $span->tag(
                        error => 1,
                    );
                    die $@;
                }
            } operation_name => 'sql prepare: ' . ($type // 'unknown');
        };
        install_modifier q{DBI::st}, around => execute => sub {
            my ($code, $sth, @bind) = @_;
            my $sql = $sth->{Statement};
            my $type = $class->type_from_sql($sql);
            return trace {
                my ($span) = @_;
                my $cursor = $sth->{CursorName};
                my $dbh = $sth->{Database};
                try {
                    $span->tag(
                        'component'       => 'DBI',
                        'span.kind'       => 'client',
                        'db.operation'    => 'execute',
                        'db.statement'    => $sql,
                        'db.type'         => 'sql',
                        (defined $cursor ? ('db.cursor'    => $cursor) : ()),
                        (defined $dbh->{Name} ? ('db.instance'         => $dbh->{Name}) : ()),
                        (defined $dbh->{Username} ? ('db.user'         => $dbh->{Username}) : ()),
                    );
                    return $sth->$code(@bind);
                } catch {
                    my $err = $@;
                    $span->tag(
                        error => 1,
                    );
                    die $@;
                }
            } operation_name => 'sql execute: ' . ($type // 'unknown');
        };
        install_modifier q{DBI::db}, around => do => sub {
            my ($code, $dbh, $sql, @rest) = @_;
            my $type = $class->type_from_sql($sql);
            return trace {
                my ($span) = @_;
                try {
                    $span->tag(
                        'component'       => 'DBI',
                        'span.kind'       => 'client',
                        'db.operation'    => 'do',
                        'db.statement'    => $sql,
                        'db.type'         => 'sql',
                        (defined $dbh->{Name} ? ('db.instance'         => $dbh->{Name}) : ()),
                        (defined $dbh->{Username} ? ('db.user'         => $dbh->{Username}) : ()),
                    );
                    return $dbh->$code($sql, @rest);
                } catch {
                    my $err = $@;
                    $span->tag(
                        error => 1,
                    );
                    die $@;
                }
            } operation_name => 'sql do: ' . ($type // 'unknown');
        };
        for my $op (qw(
            selectall_arrayref
            selectall_hashref
            selectall_array
        )) {
            install_modifier q{DBI::db}, around => $op => sub {
                my ($code, $dbh, $sql, @rest) = @_;
                my $type = $class->type_from_sql($sql);
                return trace {
                    my ($span) = @_;
                    try {
                        $span->tag(
                            'component'       => 'DBI',
                            'span.kind'       => 'client',
                            'db.operation'    => 'selectall',
                            'db.statement'    => $sql,
                            'db.type'         => 'sql',
                            (defined $dbh->{Name} ? ('db.instance'         => $dbh->{Name}) : ()),
                            (defined $dbh->{Username} ? ('db.user'         => $dbh->{Username}) : ()),
                        );
                        return $dbh->$code($sql, @rest);
                    } catch {
                        my $err = $@;
                        $span->tag(
                            error => 1,
                        );
                        die $@;
                    }
                } operation_name => 'sql selectall: ' . ($type // 'unknown');
            };
        }
    }
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< TEAM@cpan.org >>

=head1 LICENSE

Copyright Tom Molesworth 2020. Licensed under the same terms as Perl itself.

