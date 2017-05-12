use strict;
use warnings;

package Net::Amazon::Config;
# ABSTRACT: Manage Amazon Web Services credentials
our $VERSION = '0.002'; # VERSION

use Carp ();
use Config::Tiny 2.12 ();
use Net::Amazon::Config::Profile ();
use Params::Validate 0.91 ();
use Path::Class 0.17      ();
use Object::Tiny 1.06 qw(
  config_dir
  config_file
  config_path
);

use constant IS_WIN32 => $^O eq 'MSWin32';

sub _default_dir {
    my $base = Path::Class::dir( IS_WIN32 ? $ENV{USERPROFILE} : $ENV{HOME} );
    return $base->subdir('.amazon')->absolute->stringify;
}

sub new {
    my $class = shift;
    my %args  = Params::Validate::validate(
        @_,
        {
            config_dir  => { default => $ENV{NET_AMAZON_CONFIG_DIR} || _default_dir, },
            config_file => { default => $ENV{NET_AMAZON_CONFIG}     || 'profiles.conf', }
        }
    );

    if ( Path::Class::file( $args{config_file} )->is_absolute ) {
        $args{config_path} = $args{config_file};
    }
    else {
        $args{config_path} =
          Path::Class::dir( $args{config_dir} )->file( $args{config_file} );
    }

    unless ( -r $args{config_path} ) {
        die "Could not find readable file $args{config_path}";
    }

    return bless \%args, $class;
}

sub get_profile {
    my ( $self, $profile_name ) = @_;
    my $config = Config::Tiny->read( $self->config_path );

    $profile_name = $config->{_}{default} unless defined $profile_name;
    my $params = $config->{$profile_name}
      or return;

    $params->{profile_name} = $profile_name;
    my $profile = eval { Net::Amazon::Config::Profile->new($params) };
    if ($@) {
        Carp::croak "Invalid profile: $@";
    }
    return $profile;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::Config - Manage Amazon Web Services credentials

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head2 Example

     use Net::Amazon::Config;
 
     # default location and profile
     my $profile = Net::Amazon::Config->new->get_profile;
 
     # use access key ID and secret access key with S3 
     use Net::Amazon::S3;
     my $s3 = Net::Amazon::S3->new(
       aws_access_key_id     => $profile->access_key_id,
       aws_secret_access_key => $profile->secret_access_key,
     );

=head2 Config Format

   default = johndoe
   [johndoe]
   access_key_id = XXXXXXXXXXXXXXXXXXXX
   secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   certificate_file = my-cert.pem
   private_key_file = my-key.pem
   ec2_keypair_name = my-ec2-keypair
   ec2_keypair_file = ec2-private-key.pem
   aws_account_id = 0123-4567-8901
   canonical_user_id = <64-character string>

=head1 DESCRIPTION

This module lets you keep Amazon Web Services credentials in a
configuration file for use with different tools that need them.

=head1 USAGE

=head2 new() 

   my $config = Net::Amazon::Config->new( %params );

Valid C<<< %params >>> entries include:

=over

=item *

config_dir -- directory containing the config file
(and the default location for other files named in the config file).  
Defaults to C<<< $HOME/.amazon >>>

=item *

config_file -- defaults to C<<< profiles.conf >>>

=back

Returns an object or undef if no config file can be found.

=head2 config_path()

   my $path = $config->config_path;

Returns the absolute path to the configuration file.

=head2 get_profile()

   my $profile = $config->get_profile( $name );

If C<<< $name >>> is omitted or undefined, returns the profile named in the
top-level key C<<< default >>> in the config file. If the profile does not
exist, get profile returns undef or an empty list.

=head1 ENVIRONMENT

=over

=item *

NET_AMAZON_CONFIG -- absolute path to config file or file name relative
to the configuration directory

=item *

NET_AMAZON_CONFIG_DIR -- configuration directory 

=back

=head1 SEE ALSO

=over

=item *

About AWS Security Credentials: http:E<sol>E<sol>tinyurl.comE<sol>yh93cjg

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Net-Amazon-Config/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Net-Amazon-Config>

  git clone https://github.com/dagolden/Net-Amazon-Config.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
