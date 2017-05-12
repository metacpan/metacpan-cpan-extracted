use Tk; # -*- cperl -*-

package Parse::Vipar::ViparText;
use strict;
use Tk::Text;

use base 'Tk::Text';
Construct Tk::Widget 'ViparText';
use Tk::English;

use Parse::YALALR::Common;

# Setting @ISA to Exporter messes up Tk widget inheritance
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(makestart makeend find_parent foreach_tag);
sub import {
    my ($pkg, @syms) = @_;
    no strict 'refs';
    my $caller = caller(0);
    # Doesn't handle &foo; requires a plain foo
    *{"${caller}::$_"} = *{__PACKAGE__."::$_"} foreach (@syms);
}

sub ClassInit
{
    my ($class,$mw) = @_;
    $class->SUPER::ClassInit($mw);
    return $class;
}

sub InitObject {
    my ($super, $args) = @_;
    $super->bind(__PACKAGE__, "<Double-Shift-Button-1>", '');
    $super->bind(__PACKAGE__, "<Triple-Button-1>", '');
    $super->bind(__PACKAGE__, "<Double-Button-1>", '');
    $super->bind(__PACKAGE__, "<B1-Motion>", '');
    $super->bind(__PACKAGE__, "<Button-1>", '');
    $super->bind(__PACKAGE__, "<Shift-Button-1>", '');
    $super->bind(__PACKAGE__, "<Double-Shift-Button-1>", '');
    $super->bind(__PACKAGE__, "<Triple-Shift-Button-1>", '');
#    print join("\n", $super->bind(__PACKAGE__))."\n";

    $super->tagConfigure("active", -background => 'white');
    $super->tagConfigure("selected", -background => 'yellow');
    $super->tagConfigure("restricted", -background => 'red');
    $super->tagLower("selected"); # Active things should shine above
    $super->tagConfigure("center", -justify => 'center');
    $super->{default_map} = { pre => { '*' => \&default_pre },
                              post => undef };
}

sub tagCenterLink {
    my ($self, $tag, $command) = @_;
    $self->insert("$tag.first", " ");
    $self->insert("$tag.last", " ");
    $self->tagAdd("center", "$tag.first linestart", "$tag.last lineend");
    $self->tagLink($tag, $command);
}

# Can be used without the command to just change the appearance and
# activity (if, for example, you will be sticking the command on
# another overlapping tag)
#
# Note, however, that this will highlight *all* occurrences of the given tag
# when the mouse goes over any one.
#
# Pass in -link => undef (for example) to disable changing the
# foreground color.
#
sub tagLink {
    my ($self, $tag, $command, %opts) = @_;

    $opts{-alink} = 'yellow' if !exists $opts{-alink};
    $opts{-link} = 'blue' if !exists $opts{-link};
    $opts{-underline} = 1 if !exists $opts{-underline};
    $opts{-cursor} = 'hand2' if !exists $opts{-cursor};

    $self->tagConfigure($tag, -foreground => $opts{-link})
      if (defined $opts{-link});
    $self->tagConfigure($tag, -underline => $opts{-underline})
      if (defined $opts{-underline});

    my $activate;
    if (defined $opts{-alink} && defined $opts{-cursor}) {
	$activate = sub {
	    $self->tagConfigure($tag, -foreground => $opts{-alink});
	    $self->configure(-cursor => $opts{-cursor}); };
    } elsif (defined $opts{-alink}) {
	$activate = sub {
	    $self->tagConfigure($tag, -foreground => $opts{-alink}); };
    } elsif (defined $opts{-cursor}) {
	$activate = sub { $self->configure(-cursor => $opts{-cursor}); };
    };

    $self->tagBind($tag, "<Any-Enter>", $activate) if defined $activate;


    my $deactivate;
    my $link = (defined $opts{-link}) ? $opts{-link}
                                      : ($self->cget(-foreground))[3];
    if (defined $opts{-alink}) {
	$deactivate = sub {
	    $self->tagConfigure($tag, -foreground => $link);
	    $self->configure(-cursor => ''); };
    } else {
	$deactivate = sub { $self->configure(-cursor => ''); };
    };
    $self->tagBind($tag, "<Any-Leave>", $deactivate);

    $self->tagBind($tag, "<Button-1>", $command)
      if defined $command;
}

sub tagInvisibleLink {
    my ($self, $tag, $command, @opts) = @_;
    $self->tagLink($tag, $command, @opts,
		   -link => undef, -alink => undef, -underline => undef);
}

# Fix Tk::Text's misbehavior with multiple ranges
sub tagAdd {
    my ($self, $tag, @ranges) = @_;
    while (@ranges) {
	$self->SUPER::tagAdd($tag, shift(@ranges), shift(@ranges));
    }
}

# getNumericalAttrs
#
# Suck out attributes from tags like
# lookahead_state3_token17_shoesize13
#
sub getNumericalAttrs {
    my ($self, $base) = @_;
    my $r = qr/${base}_/;
    foreach ($self->curTagNames()) {
	next unless $_ =~ $r;
	my ($id) = /_(\d+)/;
	my @attrs = /_([a-zA-Z]+)(\d*)/g;
	if (defined $id) {
	    return (id => $id, @attrs);
	} else {
	    return @attrs;
	}
    }
    return ();
}

sub makeTag {
    my ($self, $base, @attrs) = @_;
    my $tag = $base;
    my $data;
    while (@attrs) {
	if ($attrs[0] eq '-data') {
	    shift(@attrs);
	    $data = shift(@attrs);
	} else {
	    $tag .= "_";
	    $tag .= shift(@attrs);
	    $tag .= shift(@attrs);
	}
    }

    if (defined $data) {
	$self->tagConfigure($tag, -data => $data);
	print "SAVING DATA $data TO tag $tag\n";
    }

    return $tag;
}

sub curTagNames {
    my $self = shift;
    return $self->tagNames('@'.$Tk::event->x.','.$Tk::event->y);
}

sub map { $_[0]->{default_map}; }

# Worry later about preserving the multiple-tags and
# prev-tag-inheriting behavior of a missing taglist in insert
#
# Args:
#  self - the textbox
#  args (optional) - { map => handler_map, opaque => opaque_data }
#  index - text index to insert stuff at
#  xml - the XML to insert into the textbox
#  tags (optional) - the tags to apply to the whole insertion
#
sub xmlinsert {
    my $self = shift;
    my $args = shift;

    my $index;
    if (!UNIVERSAL::isa($args, 'HASH')) {
        $index = $args;
        undef $args;
    } else {
        $index = shift;
    }

    my ($xml, $tags) = @_;

#    print "XML: $xml\n";

    my $map;
    if (!exists $args->{map}) {
        $map = $self->{default_map};
    } else {
        while (my ($tag, $handler) = each %{$args->{map}->{pre}}) {
#            print "$tag -> $handler\n";
            $map->{pre}->{$tag} = undef, next if !defined $handler;
            $map->{pre}->{$tag} = $handler, next if ref $handler;
            die "Huh?" if $handler ne 'default';
            $map->{pre}->{$tag} = $self->{default_map}->{pre}->{'*'};
        }
        while (my ($tag, $handler) = each %{$args->{map}->{post}}) {
            $map->{post}->{$tag} = undef, next if !defined $handler;
            $map->{post}->{$tag} = $handler, next if ref $handler;
            die "Huh?" if $handler ne 'default';
            $map->{post}->{$tag} = $self->{default_map}->{post}->{'*'};
        }
    }

    my @data;
    # <foo>blah</foo>blor -> [ "blah", [ "node_3" ], "blor", [] ]
    $xml =~ s/^([^\<]*)//;
    push(@data, $U{$1});
    while ($xml =~ /<(.*?)>([^<]*)/g) {
        my ($tag, $text) = ($1, $2);
        push @data, \$tag, $U{$text};
    }

    # Build sequence into a tree: [ text|tag ]
    # tag : { tag => tagname, body => tree, tagattrs => tagvalues }
    my $tree = _sequence_to_tree(@data);

    # Tk calling convention for tags: a scalar is equiv to a list of one elt
    if (!ref $tags) {
        $tags = (defined $tags) ? [ $tags ] : [];
    }

    unshift @$tree, (bless [ @$tags ], 'start');
    push @$tree, (bless [ @$tags ], 'end');

    my @chunks =
        $self->_xmltree_convert($tree, $map, $args && $args->{opaque}, undef);

    my @insertion;
    my %tagset;
    foreach my $elt (@chunks) {
        if (!ref $elt) {
#            print "$elt TAGGED WITH ".join(" ", keys %tagset)."\n";
            push(@insertion, $elt, [ keys %tagset ]);
        } elsif (ref $elt eq 'start') {
            $tagset{$_} = 1 foreach (@$elt);
        } elsif (ref $elt eq 'end') {
            delete $tagset{$_} foreach (@$elt);
        } else {
            die "Huh? What?";
        }
    }

    $self->insert($index, @insertion);
}

sub makestart { return bless [ @_ ], 'start' }
sub makeend { return bless [ @_ ], 'end' }

sub find_parent {
    my ($xmltag, $parenttag) = @_;
    while (1) {
	return $xmltag if $xmltag->{tag} eq $parenttag;
	return if (!defined ($xmltag = $xmltag->{parent}));
    }
}

sub foreach_tag {
    my ($body, $sub) = @_;
    foreach (@$body) {
	if (ref $_ && ref $_ ne 'start' && ref $_ ne 'end') {
	    $sub->($_);
	    foreach_tag($_->{body}, $sub);
	}
    }
}

sub default_pre {
    my ($xmltag) = @_;
    my @tags = ($xmltag->{tag});
    if (defined $xmltag->{id}) {
	push(@tags, "$tags[0]_$xmltag->{id}");
    }
    $xmltag->{body} = [ makestart(@tags), @{$xmltag->{body}}, makeend(@tags) ];
}

# Do a DFS-order traversal of the XML tree, converting it into a flat
# list of chunks of text or tag start/stop blocks.
sub _xmltree_convert {
    my ($self, $tree, $map, $opaque, $parent) = @_;
    my @chunks;
    foreach (@$tree) {
        if (!ref $_ || ref $_ eq 'start' || ref $_ eq 'end') {
            push(@chunks, $_);
        } else {
            # Call the pre-visit handler for the tag, allowing it to
            # muck with anything contained by the tag
            my $xmltag = $_;
            my $tag = $xmltag->{tag};
            my $pre = $map->{pre}->{$tag} || $map->{pre}->{'*'};

	    $xmltag->{parent} = $parent;
	    $pre->($xmltag, $opaque) if $pre;
            # Traverse into the tagged section
            my @subchunks =
                $self->_xmltree_convert($xmltag->{body}, $map, $opaque, $xmltag);
	    delete $xmltag->{parent}; # Circular reference

            # Call the post-visit handler for the tag
            # post: (tagged, elt1, elt2, ...) -> (elt)
            my $post = $map->{post}->{$tag} || $map->{post}->{'*'};
            if (defined $post) {
                push(@chunks, $post->($xmltag, $opaque, @subchunks));
            } else {
                push(@chunks, @subchunks);
            }
        }
    }

    return @chunks;
}

sub _sequence_to_tree {
    my $tree = [];
    while (@_) {
        my $elt = shift;
        if (!ref $elt) {
            push @$tree, $elt;
        } else {
            if ($$elt =~ m!^/(\w+)!) {
                # Close tag
                return ($tree, $1);
            } else {
                my ($tag, $params) = $$elt =~ /^(\w+)\s*(.*)$/;
                my @params = $params =~ /\S+/g;
                my %params = map { split(/=/, $_, 2) } @params;
                $params{tag} = $tag;
                my $check;
                ($params{body}, $check) = &_sequence_to_tree;
                push @$tree, \%params;
                die "Missing closing tag </$tag>\n"
                    if !defined $check;
                die "Badly nested tags: expected </$tag>, got </$check>\n"
                    if $tag ne $check;
            }
        }
    }

    return ($tree);
}
