# $Id: Babelfish.pm,v 1.2 2003/09/03 15:11:03 cvspub Exp $
package PerlIO::via::Babelfish;
use strict;
our $VERSION = '0.01';

our $fish;
our @setting_keys = qw(source target proxy agent);
our %setting;

use WWW::Babelfish;

sub import {
    shift;
    my $arg = ref($_[0]) ? $_[0] : {@_};
    foreach my $s ( @setting_keys ){
	$setting{$s} = $arg->{$s};
    }
    $setting{agent} ||= 'Mozilla/8.0';
    $setting{proxy} ||= 'proxy.ntu.edu.tw:3128';
    $fish = new WWW::Babelfish(
			       'agent' => $setting{agent},
			       'proxy' => $setting{proxy},
			       );
}

sub unimport {
    undef $fish;
}

sub PUSHED {
    my ($class,$mode,$fh) = @_;
    my $buf = '';
    return bless \$buf,$class;
}

sub FILL {
    my ($obj,$fh) = @_;
    my $line = <$fh>;
    if( ref($fish) and defined $line ){
	return $fish->translate(
				'source' => $setting{source},
				'destination' => $setting{target},
				'text' => $line,
				'delimiter' => '',
				);
    }
    else{
        return undef;
    }
}

sub WRITE {
    my ($obj,$buf,$fh) = @_;
    my $bt;
    $$obj .= $bt = ref($fish) ?
	$fish->translate(
			 'source' => $setting{source},
			 'destination' => $setting{target},
			 'text' => $buf,
			 'delimiter' => '',
			    ) :
				$buf;
    $obj->FLUSH($fh);
    return length($bt);
}

sub FLUSH {
    my ($obj,$fh) = @_;
    print $fh $$obj or return -1;
    $$obj = '';
    return 0;
}




1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

PerlIO::via::Babelfish - PerlIO layer for WWW::Babelfish

=head1 SYNOPSIS

  use PerlIO::via::Babelfish
    source => 'English', target => 'Spanish',
    agent => 'A A A Agent', proxy => 'Pro Pro Pro Proxy';

  binmode(STDOUT, ":via(Babelfish)") or die;

  print "i love you forever";
  # it prints 'te amo por siempre'

=head1 DESCRIPTION

=head2 source and target

Supported languages are Chinese, English, French, German, Italian, Japanese Korean, Portuguese, Russian, and Spanish.

=head2 agent and proxy

The two parameters are optional. Default agent string is "Mozilla/8.0", and default proxy is null.

=head1 TO DO

Some kind of cache mechanism for speeding up the rendering

=head1 SEE ALSO

L<WWW::Babelfish>

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
