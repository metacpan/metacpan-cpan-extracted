
#######################################################################
#######################################################################
package Pod::Peapod::Tkparser;
#######################################################################
#######################################################################

use strict;
use warnings;
use Data::Dumper;

use Pod::Peapod;

our @ISA;
push(@ISA,'Pod::Peapod');

#######################################################################
sub New
#######################################################################
{
 my ($class) = @_;
 my $parser = $class->SUPER::New();
 $parser->{_link_cursor}='arrow'; 
 $parser->{_text_cursor}='xterm';
 return $parser;
}

#######################################################################
sub OutputTocText
#######################################################################
{
	my $parser=shift(@_);
	my $toc_widget = $parser->{_toc_widget};
	my $pod_widget = $parser->{_pod_widget};

	my $text = $parser->GetAttribute('_text_string');

	my $fontstring = $parser->_current_font;

	my $position_marker = $parser->GetAttribute('_position_marker');
	$position_marker .= '_start';

	my $tag_goto_marker = 'TAG_GOTO_'.$position_marker;

	$toc_widget->tagBind
		(
		$tag_goto_marker, 
		'<Button-1>',
		sub{$pod_widget->see($pod_widget->index($position_marker));},
		);

	$toc_widget->insert('insert', $text, [$fontstring, $tag_goto_marker]);
}

#######################################################################
sub OutputTocNewLine
#######################################################################
{
	my $parser=shift(@_);
	my $toc_widget = $parser->{_toc_widget};
	$toc_widget->insert('insert', "\n");
}



#######################################################################
sub OutputPodText
#######################################################################
{
	my $parser=shift(@_);
	my $pod_widget = $parser->{_pod_widget};
	my $position_marker = $parser->GetAttribute('_position_marker');


	my $left_margin = $parser->GetAttribute('_left_margin');
	my $left_margin_tag = 'Column'.$left_margin;

	my $start_marker = $position_marker . '_start';
	my $end_marker = $position_marker . '_end';

	$pod_widget->markSet($start_marker, $pod_widget->index('insert'));
	$pod_widget->markGravity($start_marker, 'left');

	my $text = $parser->GetAttribute('_text_string');
	my $fontstring = $parser->_current_font;

	$pod_widget->insert('insert', $text, [$fontstring,$left_margin_tag]);

	$pod_widget->markSet($end_marker, $pod_widget->index('insert'));
	$pod_widget->markGravity($end_marker, 'left');
}

#######################################################################
sub OutputPodNewLine
#######################################################################
{
	my $parser=shift(@_);
	my $pod_widget = $parser->{_pod_widget};
	$pod_widget->insert('insert', "\n\n");
}

#######################################################################
#######################################################################
package Pod::Peapod::Tkpeapod;
#######################################################################
#######################################################################

require 5.005_62;
use strict;
use warnings;

our $VERSION = '0.07';

use Data::Dumper;

use Tk qw (Ev);
use Tk::ROText;
use Tk::Adjuster;

use  Pod::Simple::Methody;

use base qw(Tk::Frame);

Construct Tk::Widget 'Peapod';

#######################################################################
#######################################################################
sub ClassInit
#######################################################################
{ 
 my ($class,$mw) = @_;
 $class->SUPER::ClassInit($mw);

 $mw->bind($class,'<F1>', 'DumpMarks'); 
 $mw->bind($class,'<F2>', 'DumpTags'); 
 $mw->bind($class,'<F3>', 'DumpCursor'); 
}


#######################################################################
sub set_font_tags
#######################################################################
{
	# pass in a list of font sizes to correspond to the 4 text sizes
	# by default, use these values:	
	my ($self, @font_sizes)=@_; # 

	my $pod = $self->Subwidget('pod');
	my $toc = $self->Subwidget('toc');

	unless(scalar(@font_sizes))
		{
		@font_sizes= qw( 18 16 12 10 );
		}

	unshift(@font_sizes, 'EMTPY');

 	for(my $i=0; $i<100; $i++)
		{
		 $pod->tagConfigure
			(
				'Column'.$i,
	 			-lmargin1 => $i*8,
				-lmargin2 => $i*8,
			);
		}

	# family    =>  garamond, courier
	# size 	    =>  10, 12, 16, 18
	# weight    =>  normal, bold
	# slant     =>  roman, italic
	# underline =>  yesunder, nounder

for my $family qw(lucida courier)
	{
	for my $relative_size qw ( 1 2 3 4 )
		{
		my $font_size = $font_sizes[$relative_size];

		for my $weight qw(normal bold)
			{
			for my $slant qw(roman italic)
				{
				for my $under qw (yesunder nounder)
					{
					my $underval = ($under eq 'yesunder') ? 1 : 0;
					my $tagname = $family.$relative_size.$weight.$slant.$under;
					my @args = 
						(
						$tagname,
						-font =>
							[
							-family=>$family,
							-size  =>$font_size,
							-weight=>$weight,
							-slant =>$slant,
							],
						,
						);


					$pod->tagConfigure(@args, -underline => $underval);
					$toc->tagConfigure(@args, -underline => 0);


					# warn "tagname is '$tagname'";
					}
				}
			}
		}
	}

}

#######################################################################
sub Populate
#######################################################################
{
	my($self, $args)=@_;

	$self->SUPER::Populate($args);

	my $toc = $self->Scrolled
		(
		'ROText',
		-width => 30 
		)
		->pack(-side=> 'left',-fill=>'both');
	
	$toc->configure(-wrap=>'none');

	my $adj = $self->Adjuster(-widget=>$toc, -side=>'left')
		->pack(-side=>'left',-fill=>'y');

	my $pod = $self->Scrolled
		(
		'ROText',
		-width => 80 
		)
		->pack(-side=>'right',-fill=>'both',-expand=>1);

	$self->Advertise  (    'toc'=> $toc );
	$self->Advertise  (    'pod'=> $pod );
	$self->ConfigSpecs('DEFAULT'=>[$pod]);
	$self->Delegates  ('DEFAULT'=> $pod );

	$self->Delegates  ('podview'=>$self);

	$self->set_font_tags;

	my $parser = Pod::Peapod::Tkparser->New();
	$self->{_parser}= $parser;
	$parser->{_widget}=$self;
	$parser->{_pod_widget}=$pod;
	$parser->{_toc_widget}=$toc;
	

	$pod->configure(-cursor=>$parser->{_text_cursor});

	$pod->bind('<F1>', sub{$self->DumpMarks}); 
	$pod->bind('<F2>', sub{$self->DumpTags}); 
	$pod->bind('<F3>', sub{$self->DumpCursor}); 

}






#######################################################################
#######################################################################

#######################################################################
sub podview
#######################################################################
{
	my ($widget, $string)=@_;

	$widget->{_parser}->parse_string_document($string);
}


#######################################################################
sub by_line_number
#######################################################################
{
	($a->[0]) <=> ($b->[0]);
}

#######################################################################
sub DumpMarks
#######################################################################
{
	my ($bigwidget)=@_;
	my $widget = $bigwidget->Subwidget('pod');

	my @marknames = $widget->markNames;

	my @index_mark;
	foreach my $markname (@marknames)
		{
		my $index = $widget->index($markname);
		my ($ln, $col)=split(/[.]/, $index);

		push(@index_mark,[$ln+0,$col+0,$markname]);
		}

	my @sorted = sort by_line_number @index_mark;

	foreach my $arr_ref (@sorted)
		{
		my($ln,$col,$markname)=@$arr_ref;
		my $string = 
			sprintf("% 10u\.% 6u", $ln, $col) . "  $markname\n";
		print $string;
		}

}


#######################################################################
sub DumpTags
#######################################################################
{
	my ($bigwidget)=@_;
	my $widget = $bigwidget->Subwidget('pod');

	my @tagname = $widget->tagNames;

	foreach my $tag (@tagname)
		{
		my @indexes = $widget->tagRanges($tag);
		next unless(scalar(@indexes));
		print "\n\n";
		print "tag name '$tag'\n";
		for(my $i=0; $i<scalar(@indexes); $i=$i+2)
			{
			my $start = $indexes[$i];
			my $end   = $indexes[$i+1];
			print "\t $start $end \n";
			}
		}
}


#######################################################################
sub DumpCursor
#######################################################################
{
	my ($bigwidget)=@_;
	my $widget = $bigwidget->Subwidget('pod');

	my @tagname = $widget->tagNames('insert');
	print "\n\n";

	foreach my $tag (@tagname)
		{
		my @indexes = $widget->tagRanges($tag);
		next unless(scalar(@indexes));
		#print "\n\n";
		print "tag name '$tag'\n";
		for(my $i=0; $i<scalar(@indexes); $i=$i+2)
			{
			my $start = $indexes[$i];
			my $end   = $indexes[$i+1];
		#	print "\t $start $end \n";
			}
		}
}


1;
__END__


=head1 NAME

Pod::Peapod::Tkpeapod - POD viewer

=head1 SYNOPSIS

	use Tk;
	use Pod::Peapod::Tkpeapod;
	
	my $top = MainWindow->new();

	my $peapod = $top->Peapod-> pack;	
	
	{
		local $/;
		my $string = <>;
		$peapod->podview($string);
	}
	
	MainLoop();
	
=head1 ABSTRACT

Pod::Peapod::Tkpeapod is a POD viewing widget that can be used in Perl/Tk.

The tarball also includes a script called 'peapod' which is a POD viewer.

=head1 DESCRIPTION

Pod::Peapod::Tkpeapod is a POD viewing widget that can be used in Perl/Tk.

The tarball also includes a script called 'peapod' which is a POD viewer.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Pod::Peapod : base class for Pod::Peapod::Tkpeapod (included)
peapod : perl script using Pod::Peapod::Tkpeapod to create a POD viewer. (included)
Pod::Simple (on CPAN)

=head1 AUTHOR

Greg London, http://www.greglondon.com

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Greg London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut









