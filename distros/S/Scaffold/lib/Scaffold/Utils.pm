package Scaffold::Utils;

our $VERSION = '0.01';

use 5.8.8;
use Try::Tiny;
use Crypt::CBC;
use Badger::Exception trace => 1;

use Scaffold::Class
  version    => $VERSION,
  base       => 'Badger::Utils',
  codec      => 'Base64',
  filesystem => 'File',
  exports => {
      any => 'encrypt decrypt init_module',
  },
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub decrypt {
    my ($secret, $encrypted) = @_;

    my $c;
    my $base64;
    my $p_text;

    $encrypted ||= '';

    local $^W = 0;

    try {

        $c = Crypt::CBC->new( 
            -key    => $secret,
            -cipher => 'Crypt::OpenSSL::AES',
        );

        $base64 = decode($encrypted);
        $p_text = $c->decrypt($base64);
        $c->finish();

    } catch {

        my $x = $_;
        my $ex = Badger::Exception->new(
            type => 'scaffold.utils.decrypt',
            info => $x,
        );

        $ex->throw;

    };

    return $p_text;

}

sub encrypt {
    my ($secret, @to_encrypt) = @_;

    my $c;
    my $str;
    my $encd;
    my $c_text;

    local $^W = 0;

    try {

        $c = Crypt::CBC->new( 
            -key   => $secret,
            -cipher => 'Crypt::OpenSSL::AES',
        );

        $str    = join('', @to_encrypt);
        $encd   = $c->encrypt($str);
        $c_text = encode($encd);

        $c->finish();

    } catch {

        my $x = $_;
        my $ex = Badger::Exception->new(
            type => 'scaffold.utils.encrypt',
            info => $x,
        );

        $ex->throw;

    };

    return $c_text;

}

sub init_module {
    my ($module, $sobj) = @_;

    my $obj;
    my @parts;
    my $filename;

    if ($module) {

        @parts = split("::", $module);
        $filename = File(@parts);

        try {

            require $filename . '.pm';
            $module->import();
            $obj = $module->new(scaffold => $sobj);

        } catch {

            my $x = $_;
            my $ex = Badger::Exception->new(
                type => 'scaffold.utils.init_module',
                info => $x
            );

            $ex->throw;

        };

    } else {

        my $ex = Badger::Exception->new(
            type => 'scaffold.utils.init_module',
            info => 'no module was defined'
        );

        $ex->throw;

    }

    return $obj;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Utils - Utilitiy functions for Scaffold

=head1 SYNOPSIS

This module provides some basic utility functions for Scaffold.

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item encrypt( secret [, ... ] )

Encrypts and returns the encrypted string using Crypt::CBC along with 
Crypt::OpenSSL::AES. 

=item decrypt( secret, 'string' )

Decrypts and returns the encrypted string using Crypt::CBC along with 
Crypt::OpenSSL::AES. 

=item init_module( 'module' )

load and initializes a module

=back

=head1 SEE ALSO

 Crypt::CBC
 Badger::Utils
 Crypt::OpenSSL::AES

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
