package TRD::Velocity;

#use warnings;
use strict;

=head1 NAME

TRD::Velocity - Template engine

=head1 VERSION

Version 0.0.8

=cut

our $VERSION = '0.0.8';
our $debug = 0;

=head1 SYNOPSIS

    use TRD::Velocity;

    $velo = new TRD::Velocity;
    $velo->setTemplateFile( 'foo.html' );
    $velo->set( 'name', 'value' );
    $html_stmt = $velo->marge();
    $ct = length( $html_stmt );
    print "Content-Type: text/html\n";
    print "Content-Length: ${ct}\n";
    print "\n";
    print $html_stmt;

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

    new Constructor.

    my $velo = new TRD::Velocity;

=cut
#======================================================================
sub new {
	my $pkg = shift;
	bless {
		params => undef,
		templateFile => undef,
		templateData => '',
		contents => '',
		command => '',
		elsecommand => '',
		options => undef,
	}, $pkg;
};

=head2 set( <name>, <value> )

    set parameter.

    $velo->set( 'itemname', 'Apple' );

=cut
#======================================================================
sub set {
	my $self = shift;
	my $name = shift;
	my $value = shift;

	$self->{params}->{$name} = $value;
}

=head2 setTemplateFile( <TemplateFileName> )

    set Template file.

    $velo->setTemplateFile( './template/soldmail.txt' );

=cut
#======================================================================
sub setTemplateFile {
	my $self = shift;
	my $templateFile = shift;
	my $fdata;

	$self->{templateFile} = $templateFile;

	open( my $fh, '<', $self->{templateFile} )|| die $!;
	while( <$fh> ){
		$fdata .= $_;
	}
	close( $fh );

	$self->{templateData} = $fdata;
}

=head2 setTemplateData( <TemplateData> )

    set Template data.

    my $template =<<EOT;
    Sender: ${sender}
    Email: ${email}
    EOT
    $velo->setTemplateData( $template );
=cut
#======================================================================
sub setTemplateData {
	my $self = shift;
	my $templateData = shift;

	$self->{templateFile} = undef;

	$self->{templateData} = $templateData;
}

=head2 marge

    Marge template to parameters.

    my $doc = $velo->marge();

=cut
#======================================================================
sub marge {
	my $self = shift;
	my $contents;

	$contents = $self->{templateData};

	if( $debug ){
		$contents =~s/([\t| ]*##.*)\n/<!--${1}-->\n/g;
	} else {
		$contents =~s/[\t| ]*##.*\n//g;
	}

	$contents = $self->tag_handler( $contents );
	$contents =~s/\${([\w\.-\[\]]+)}\.escape\(\)/$self->marge_val( $1. '.escape()' )/egos;
	$contents =~s/\${([\w\.-\[\]]+)}\.unescape\(\)/$self->marge_val( $1. '.unescape()' )/egos;
	$contents =~s/\${([\w\.-\[\]]+)}/$self->marge_val( $1 )/egos;

	$contents;
}

=head2 tag_handler

    private function.

=cut
#======================================================================
sub tag_handler {
	my $self = shift;
	$self->{contents} = shift;
	my( $htm, $tag, $contents );
	my @s;

	$contents = '';
	while( $self->{contents} ne '' ){
		#( $htm, $tag, $self->{contents} ) = split( /(#if|#foreach)/is, $self->{contents}, 2 );
		@s = split( /(#if|#foreach)/is, $self->{contents}, 2 );
		if( scalar( @s ) >= 3 ){
			$self->{contents} = $s[2];
		} else {
			$self->{contents} = '';
		}
		if( scalar( @s ) >= 2 ){
			$tag = $s[1];
		#if( defined $tag ){
			if( $tag eq '#if' ){
				$self->if_sub();
			} elsif( $tag eq '#foreach' ){
				$self->foreach_sub();
			}
		}
		if( scalar( @s ) >= 1 ){
			$htm = $s[0];
		#if( defined $htm ){
			$contents .= $htm;
		}
	}

	$contents;
}

=head2 if_sub

    private function.

=cut
#======================================================================
sub if_sub {
	my $self = shift;
	my $contents = '';
	my( $joken, $str, $stat, $cmd );

	$self->get_end();

	if( $self->{command} =~m/^\((.*?)\)(.*)/s ){
		$joken = $1;
		$str = $2;

		my @jokens = split( ' ', $joken );
		for( my $i=0; $i<scalar( @jokens ); $i++ ){
			my $joken = $jokens[$i];
			if( ($joken =~s/\$([\w\.-]+)\[(\d+)\]\.([\w\.-]+)\[(\d+)\]\.([\w\.-]+)/\$self->{params}->{$1}[$2]->{$3}[$4]->{$5}/g) ){
			} elsif( ($joken =~s/\$([\w\.-]+)\[(\d+)\]\.([\w\.-]+)/\$self->{params}->{$1}[$2]->{$3}/g) ){
			} elsif( ($joken =~s/\$([\w\.-]+)\.([\w\.-]+)/\$self->{params}->{$1}->{$2}/g) ){
			} elsif( ($joken =~s/\$([\w\.-]+)/\$self->{params}->{$1}/g) ){
			} else {
			}
			$jokens[$i] = $joken;
		}
		$joken = join( ' ', @jokens );
#print STDERR "joken=${joken}\n";

		$stat = 0;
		$cmd = qq!\$stat = 1 if( $joken );!;
		eval( $cmd ); ## no critic
		if( $stat ){
			if( $debug ){
				$contents .= "<!-- if(${joken}) -->". $str. "<!-- else ". $self->{elsecommand}. " end-->";
			} else {
				$contents .= $str;
			}
		} else {
			if( $debug ){
				$contents .= "<!-- if(${joken}) ${str} else -->". $self->{elsecommand}. "<!-- end -->";
			} else {
				$contents .= $self->{elsecommand};
			}
		}
	}

	$self->{contents} = $contents. $self->{contents};
}

=head2 foreach_sub

    private function.

=cut
#======================================================================
sub foreach_sub {
	my $self = shift;
	my( $contents, $cmd );

	$contents = '';

	$self->get_end();

	if( $self->{command} =~m/^\((.*?)\)(.*)$/s ){
		my $joken = $1;
		my $str = $2;
		my( $param1, $param2, $param3 );
		if( $joken =~m/^\s*\$(\w+?)\s+in\s+\$([\w\.\[\]]+?)\s*$/ ){
			$param1 = $1;
			$param2 = $2;
		}
		my @parts = split( /\./, $param2 );
		my $cnt = scalar( @parts );
		$param3 = $param2;
		$param3 =~s/(\w+)/\{${1}\}/g;
		$param3 =~s/\[\{(\d+)\}\]/\[${1}\]/g;
		$param3 =~s/\./->/g;
		$param3 = '$self->{params}->'. $param3;
		my $stat = 0;
		$cmd = qq!\$stat = 1 if( exists( $param3 ) );!;
		eval( $cmd ); ## no critic
		if( $@ ){
			print STDERR "ERROR: $@: ${cmd}<br>\n";
			$contents .= "ERROR: $@: ${cmd}";
		}
		if( $stat ){
			my @datas;
			$cmd = qq!\@datas = \@{${param3}};!;
			eval( $cmd ); ## no critic
			my $buff;
			my $cnt = 0;
			foreach my $item ( @datas ){
				$buff = $str;
				$buff =~s/\${$param1\./\${$param2\[$cnt\]\./g;
				$buff =~s/\$$param1\./\$$param2\[$cnt\]\./g;
				$contents .= $buff;
				$cnt ++;
			}
		} else {
			print STDERR "ERROR: foreach_sub: not exist ${param3}\n";
			$contents .= "ERROR: foreach_sub: not exist ${param3}";
		}
	}

	$self->{contents} = $contents. $self->{contents};
}

=head2 get_end

    private function.

=cut
#======================================================================
sub get_end {
	my $self = shift;
	my( $htm, $tag, $retstr );
	my $if = 0;
	my $mode = 0;

	$self->{command} = '';
	$self->{elsecommand} = '';

	while( $self->{contents} ne '' ){
		( $htm, $tag, $self->{contents} ) = split( /(#if|#foreach|#end|#else)/is, $self->{contents}, 2 );
		$retstr .= $htm;
		if(( $tag eq '#if' )||( $tag eq '#foreach' )){
			$if += 1;
		} elsif( $tag eq '#end' ){
			if( $if == 0 ){
				last;
			}
			$if -= 1;
		} elsif( $tag eq '#else' ){
			if( $if == 0 ){
				$mode = 1;
				$self->{command} = $retstr;
				$retstr = '';
				$tag = '';
			}
		}
		$retstr .= $tag;
	}

	if( $mode == 0 ){
		$self->{command} = $retstr;
	} else {
		$self->{elsecommand} = $retstr;
	}
}

=head2 marge_val

    private function.

=cut
#======================================================================
sub marge_val {
	my $self = shift;
	my $ch_name = shift;
	my $retstr;
	my $escape = 1;

	my $param = $ch_name;
	if( $param =~s/\.escape\(\)$//g ){
		$escape = 1;
	} elsif( $param =~s/\.unescape\(\)$//g ){
		$escape = 0;
	}
	$param =~s/(\w+)/\{${1}\}/g;
	$param =~s/\[\{(\d+)\}\]/\[${1}\]/g;
	$param =~s/\./->/g;
	$param = '$self->{params}->'. $param;
	my $cmd = qq!\$retstr = $param;!;
	eval( $cmd ); ## no critic
	if( $escape ){
		if( defined( $retstr ) ){
			$retstr =~s/&/&amp;/g;
			$retstr =~s/"/&quot;/g;
			$retstr =~s/'/&#39;/g;
			$retstr =~s/</&lt;/g;
			$retstr =~s/>/&gt;/g;
		}
	}
#print STDERR "\$ch_name=${ch_name}, \$param=${param}, \$escape=${escape}\n";

	$retstr;
}

=head2 dump

   Dump parameters.

=cut
#======================================================================
sub dump {
	my $self = shift;

	use Dumpvalue;

	my $d = Dumpvalue->new();
	print $d->dumpValue( \$self->{params} );
	if( defined $self->{templateFile} ){
		print "templateFile=". $self->{templateFile}. "\n";
	}
	if( defined $self->{templateData} ){
		print "templateData=". $self->{templateData}. "\n";
	}
}


=head1 AUTHOR

Takuya Ichikawa, C<< <trd.ichi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-trd-velocity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TRD-Velocity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TRD::Velocity


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TRD-Velocity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TRD-Velocity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TRD-Velocity>

=item * Search CPAN

L<http://search.cpan.org/dist/TRD-Velocity>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Takuya Ichikawa, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of TRD::Velocity
