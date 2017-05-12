package STF::Dispatcher::PSGI::HTTPException;
use strict;
use Carp ();

sub throw {
    my $class = shift;
    Carp::croak( bless [@_], $class );
}

sub as_psgi {
    my @res = @{$_[0]};
    $res[0] ||= 500;
    $res[1] ||= [];
    $res[2] ||= [];
    return \@res;
}

1;

__END__

=head1 NAME

STF::Dispatcher::PSGI::HTTPException - Very Light Exception For STF Dispatcher

=head1 SYNOPSIS

    use STF::Dispatcher::PSGI::HTTPException;
    STF::Dispatcher::PSGI::HTTPException->throw( $code );
    STF::Dispatcher::PSGI::HTTPException->throw( $code, \@hdrs );
    STF::Dispatcher::PSGI::HTTPException->throw( $code, \@hdrs, \@content );

=head1 DESCRIPTION

This class is a very lightweight fallback for STF Dispatcher modules to abort
request processing and immediately return a HTTP response.

This is meant to be used in conjunction with Plack::Middleware::HTTPExceptions. 

You are free to use other modules such ash HTTP::Exception. This module only exists so that we don't have to add an extra dependency to STF::Dispatcher::PSGI (which should just be the interface, so should be as light as possible)

=cut