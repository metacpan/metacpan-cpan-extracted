package Reply::Config;
our $AUTHORITY = 'cpan:DOY';
$Reply::Config::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: config loading for Reply

use Config::INI::Reader::Ordered;
use File::HomeDir;
use File::Spec;



sub new {
    my $class = shift;
    my %opts = @_;

    $opts{file} = '.replyrc'
        unless defined $opts{file};

    my $file = File::Spec->catfile(
        (File::Spec->file_name_is_absolute($opts{file})
            ? ()
            : (File::HomeDir->my_home)),
        $opts{file}
    );

    my $self = bless {}, $class;

    $self->{file} = $file;
    $self->{config} = Config::INI::Reader::Ordered->new;

    return $self;
}


sub file { shift->{file} }


sub data {
    my $self = shift;

    return $self->{config}->read_file($self->{file});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Config - config loading for Reply

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  use Reply;
  use Reply::Config;

  Reply->new(config => Reply::Config->new(file => 'something_else'))->run;

=head1 DESCRIPTION

This class abstracts out the config file loading, so that other applications
can start up Reply shells using similar logic. Reply configuration is specified
in an INI format - see L<Reply> for more details.

=head1 METHODS

=head2 new(%opts)

Creates a new config object. Valid options are:

=over 4

=item file

Configuration file to use. If the file is specified by a relative path, it will
be relative to the user's home directory, otherwise it will be used as-is.

=back

=head2 file

Returns the absolute path to the config file that is to be used.

=head2 data

Returns the loaded configuration data.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
