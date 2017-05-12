package Net::Async::Webservice::Common::WithConfigFile;
$Net::Async::Webservice::Common::WithConfigFile::VERSION = '1.0.2';
{
  $Net::Async::Webservice::Common::WithConfigFile::DIST = 'Net-Async-Webservice-Common';
}
use Moo::Role;
use Net::Async::Webservice::Common::Exception;
use namespace::autoclean;
use 5.010;

# ABSTRACT: automatically load constructor args from a config file


around BUILDARGS => sub {
    my ($orig,$class,@args) = @_;

    my $ret = $class->$orig(@args);

    if (my $config_file = delete $ret->{config_file}) {
        $ret = {
            %{_load_config_file($config_file)},
            %$ret,
        };
    }

    return $ret;
};

sub _load_config_file {
    my ($file) = @_;
    require Config::Any;
    my $loaded = Config::Any->load_files({
        files => [$file],
        use_ext => 1,
        flatten_to_hash => 1,
    });
    my $config = $loaded->{$file};
    Net::Async::Webservice::Common::Exception::ConfigError->throw({
        file => $file,
    }) unless $config;
    return $config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::Common::WithConfigFile - automatically load constructor args from a config file

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  package My::WS::Client {
   use Moo;
   with 'Net::Async::Webservice::Common::WithConfigFile';
   has param => (is => 'ro', required => 1);
  }

  my $c = My::WS::Client->new({config_file=>'/etc/my.conf'});

=head1 DESCRIPTION

This role wraps C<BUILDARGS> and, if a C<config_file> argument was
passed to the constructor, loads that file with L<Config::Any> and
adds the values loaded to the arguments (explicitly passed constructor
arguments still take precedence).

=head1 SEE ALSO

L<MooX::ConfigFromFile> for a more comprehensive solution.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
