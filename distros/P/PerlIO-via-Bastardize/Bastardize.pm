package PerlIO::via::Bastardize;
use 5.006;
use strict;
use Text::Bastardize;

our $VERSION = '0.01';
our $method;

our $bastard = new Text::Bastardize;
sub import {
    shift;
    my $arg = ref($_[0]) ? $_[0] : {@_};
    $method = $arg->{method} || die "Method?\n";
}

sub PUSHED {
    my ($class,$mode,$fh) = @_;
    my $buf = '';
    return bless \$buf,$class;
}

sub FILL {
    my ($obj,$fh) = @_;
    my $line = <$fh>;
    my $ret;
    if( defined $line ){
	$bastard->charge($line);
	eval '$ret = join q//, $bastard'."->$method(\$buf);";
	return $ret;
    }
    else{
	return undef;
    }
}

sub WRITE {
    my ($obj,$buf,$fh) = @_;
    my $bt;
    $bastard->charge($buf);
    eval '$$obj .= $bt = join q//,'."\$bastard->$method(\$buf);";
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

PerlIO::via::Bastardize - PerlIO layer for bastardizing text

=head1 SYNOPSIS

  use PerlIO::via::Bastardize method => 'pig';
  binmode(STDOUT, ":via(Bastardize)") or die;

  print "I am bastard!";


=head1 DESCRIPTION

This module is a PerlIO layer for Text::Bastardize. See also L<Text::Bastardize> for detail.

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
