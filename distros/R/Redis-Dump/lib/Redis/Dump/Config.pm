
package Redis::Dump::Config;

use Moose;
use MooseX::Types::Path::Class;
with 'MooseX::Getopt';

use JSON;
use Redis 1.904;

# ABSTRACT: It's a simple way to dump and backup config from redis-server
our $VERSION = '0.016'; # VERSION

has _conn => (
    is       => 'ro',
    isa      => 'Redis',
    init_arg => undef,
    lazy     => 1,
    default  => sub { Redis->new( server => shift->server ) }
);

sub _get_config {
    my $self = shift;
    my %cf;
    my $filter = $self->filter;
    my @configs = $self->_conn->config( 'get', $filter ? "*$filter*" : '*' );
    for ( my $loop = 0; $loop < scalar(@configs) / 2; $loop++ ) {
        my $name = $configs[ $loop * 2 ];
        my $value = $configs[ ( $loop * 2 ) + 1 ] || '';
        $cf{$name} = $value;
    }

    return %cf;
}

sub _restore {
    my $self = shift;
    my %keys = %{ from_json( $self->restore->slurp ) };
    foreach my $key ( keys %keys ) {
        my $value = $keys{$key} || "";
        warn "config set $key $value";
        $self->_conn->config( 'set', $key, $value );
    }
}


sub run {
    my $self = shift;

    $self->_restore if $self->has_restore;

    return $self->_get_config;
}


has server => (
    is            => 'ro',
    isa           => 'Str',
    default       => '127.0.0.1:6379',
    documentation => 'Host:Port of redis server (ex. 127.0.0.1:6379)'
);


has filter => (
    is            => 'ro',
    isa           => 'Str',
    default       => '',
    predicate     => 'has_filter',
    documentation => 'String to filter keys stored in redis server'
);


has restore => (
    is            => 'ro',
    isa           => 'Path::Class::File',
    coerce        => 1,
    predicate     => 'has_restore',
    documentation => 'Restore a config redis server to the server',
);

1;



=pod

=head1 NAME

Redis::Dump::Config - It's a simple way to dump and backup config from redis-server

=head1 VERSION

version 0.016

=head1 SYNOPSIS

    use Redis::Dump::Config;
    use Data::Dumper;

    my $dump = Redis::Dump::Config->new({ server => '127.0.0.6379', filter => 'foo' });

    print Dumper( \$dump->run );

=head1 DESCRIPTION

It's a simple way to dump config from redis-server in JSON format or any format
you want.

=head1 COMMAND LINE API

This class uses L<MooseX::Getopt> to provide a command line api. The command line options map to the class attributes.

=head1 METHODS

=head2 new_with_options

Provided by L<MooseX::Getopt>. Parses attributes init args from @ARGV.

=head2 run

Perfomas the actual dump.

=head1 ATTRIBUTES

=head2 server

Host:Port of redis server, example: 127.0.0.1:6379.

=head2 filter

String to filter keys stored in redis server.

=head2 restore

Restore a config redis server to the server.

=head1 DEVELOPMENT

Redis::Dump is a open source project for everyone to participate. The code repository
is located on github. Feel free to send a bug report, a pull request, or a
beer.

L<http://www.github.com/maluco/Redis-Dump>

=head1 SEE ALSO

L<Redis::Dump::Restore>, L<App::Redis::Dump>, L<App::Redis::Dump::Restore>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Redis::Dump

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Redis-Dump>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Redis-Dump>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Redis-Dump>

=item * Search CPAN

L<http://search.cpan.org/dist/Redis-Dump>

=back

=head1 AUTHOR

Thiago Rondon <thiago@nsms.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Thiago Rondon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__



