package String::StringLight;

use strict;
use warnings;

our $VERSION = '0.02';

BEGIN {
	use Exporter;
	our @ISA         = qw( Exporter );
	our @EXPORT      = qw( );
	our %EXPORT_TAGS = ( );
	our @EXPORT_OK   = qw( &trim &trimArray &space &left );
}

sub trim {
	my $s = shift;
	$s =~ s/\s+$//;
	$s =~ s/^\s+//;
	$s;
}

sub trimArray {
	for (@_){
		s/\s+$//;
	   s/^\s+//;
	}
	@_;
}

sub space {
	my $s = shift;
	my $t;
	$t .= ' ' x $s;
	return $t;
}

sub left {
	my $r = $_[0];
	while(length($r) < $_[1]) {$r.=' '}
	$r;
}	

1;
__END__

=pod

=head1 NAME

StringLight - a module for Textfunctions

=head1 SYNOPSIS

  use warnings;
  use strict;
  use String::StringLight;

  my ($string, $string1) = ("Hello", "World");
  $string = trim($string);
  trimArray($string, $string1);
  $string = space(3)."Test";
  $string = left($string,20);   

=head1 ABSTRACT

Test

=head1 DESCRIPTION

...

=head1 AUTHOR AND LICENSE

copyright 2009 (c)
Gernot Havranek

=cut
