package Padre::Help::PIR;
BEGIN {
  $Padre::Help::PIR::VERSION = '0.31';
}

# ABSTRACT: PIR Help Provider

use 5.008;
use strict;
use warnings;

use Cwd ();
use Padre::Logger;
use Padre::Help            ();
use Padre::Pod2HTML        ();
use Padre::Util            ();

our @ISA     = 'Padre::Help';

#
# Initialize help
#
sub help_init {
	my $self = shift;

	# TODO factor out and stop requireing PARROT_DIR
	return if not $ENV{PARROT_DIR};

	# TODO what is the difference between docs/book/pir and docs/ops ?
	my $dir = "$ENV{PARROT_DIR}/docs/ops";

	my %index;

	#foreach my $file ('io.pod') {
	#my $path = "$dir/$file";
	foreach my $path ("$ENV{PARROT_DIR}/docs/pdds/pdd19_pir.pod") {
		open my $fh, '<', $path;
		if ( !$fh ) {
			warn "Could not open $path $!";
			next;
		}
		my %item;
		my $cnt = 0;
		my $topic;
		while ( my $line = <$fh> ) {
			$cnt++;
			if ( $line =~ /=item\s+(\.\w+)/ ) {
				if ($topic) {
					TRACE($topic) if DEBUG;
					$item{end} = $cnt - 1;
					push @{ $index{$topic} }, {%item};
				}
				$topic = $1;
				%item = ( start => $cnt, file => $path );
				next;
			}
			if ( $line =~ /^=/ and $topic ) {
				$item{end} = $cnt - 1;
				push @{ $index{$topic} }, {%item};
				$topic = undef;
				%item  = ();
				next;
			}
		}
	}
	foreach my $path ( glob "$dir/*.pod" ) {
		if ( open my $fh, '<', $path ) {
			my %item;
			my $cnt = 0;
			my $topic;
			while ( my $line = <$fh> ) {
				$cnt++;
				if ( $line =~ /=item\s+B<(\w+)>/ ) {
					if ($topic) {
						TRACE($topic) if DEBUG;
						$item{end} = $cnt - 1;
						push @{ $index{$topic} }, {%item};
					}
					$topic = $1;
					%item = ( start => $cnt, file => $path );
					next;
				}
				if ( $line =~ /^=/ and $topic ) {
					$item{end} = $cnt - 1;
					push @{ $index{$topic} }, {%item};
					$topic = undef;
					%item  = ();
					next;
				}
			}
		} else {
			warn "Could not open '$path': $!";
		}
	}

	$self->{pir} = \%index;
}


#
# Renders the help topic content into XHTML
#
sub help_render {
	my ( $self, $topic ) = @_;
	my ( $html, $location );

	TRACE("render '$topic'") if DEBUG;

	#use Data::Dumper;
	#TRACE(Dumper $self->{pir}) if DEBUG;
	return if not $self->{pir}->{$topic};
	my $pod;

	# TODO read the files only once!?
	foreach my $x ( @{ $self->{pir}->{$topic} } ) {
		if ( open my $fh, '<', $x->{file} ) {
			my @lines = <$fh>;
			$pod .= join '', @lines[ $x->{start} .. $x->{end} ];
		}
	}
	TRACE($pod) if DEBUG;
	$html = Padre::Pod2HTML->pod2html($pod);
	TRACE($html) if DEBUG;

	return ( $html, $location || $topic );
}

#
# Returns the help topic list
#
sub help_list {
	my $self = shift;
	return [ sort keys %{ $self->{pir} } ];
}

1;



=pod

=head1 NAME

Padre::Help::PIR - PIR Help Provider

=head1 VERSION

version 0.31

=head1 DESCRIPTION

PIR Help index is built here and rendered.

=head1 AUTHORS

=over 4

=item *

Gabor Szabo L<http://szabgab.com/>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

