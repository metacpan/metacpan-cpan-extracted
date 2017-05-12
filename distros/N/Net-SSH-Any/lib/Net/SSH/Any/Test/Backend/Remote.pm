package Net::SSH::Any::Test::Backend::Remote;

use strict;
use warnings;

use Net::SSH::Any;
use Net::SSH::Any::Constants qw(SSHA_BACKEND_ERROR);

use parent 'Net::SSH::Any::Test::Backend::_Base';

sub _start_and_check {
    my $tssh = shift;

    for my $uri (@{$tssh->{uris}}) {
        $tssh->_check_and_set_uri($uri) and return 1;
        for my $key_path (@{$tssh->{key_paths}}) {
            my $uri2 = Net::SSH::Any::URI->new($uri->uri);
            $uri2->set(password => ());
            $uri2->set(key_path => $key_path);
            $tssh->_check_and_set_uri($uri2) and return 1;
        }
        for my $password (@{$tssh->{passwords}}) {
            my $uri2 = Net::SSH::Any::URI->new($uri->uri);
            $uri2->set(password => $password);
            $uri2->set(key_path => ());
            $tssh->_check_and_set_uri($uri2) and return 1;
        }
    }
    $tssh->_set_error(SSHA_BACKEND_ERROR, "SSH server not found");
    ()
}

sub _is_localhost {
    my ($tssh, $ssh) = @_;
    my $fn = $tssh->_backend_wfile(sprintf("localhost-check-%06d", int rand 1000000));
    $fn = File::Spec->rel2abs($fn);
    open my($fh), '>', $fn or return;
    print $fh "hello!\n";
    close $fh or return;

    $ssh //= $tssh->_new_ssh_client($tssh->uri) // return;
    my %rfn = ( $fn => 1,
               $tssh->_os_unix_path($fn) => 1 );
    for my $rfn (keys %rfn) {
        return 1 if $ssh->scp_get_content($rfn) =~ /hello/;
        for my $cmd ("cat $rfn",
                     "type $rfn") {
            return 1 if $ssh->capture({stderr_discard => 1}, $cmd) =~ /hello/;
        }
    }
    0;
}

1;
