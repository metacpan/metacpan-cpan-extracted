package QWizard::Plugins::History;

our $VERSION = '3.15';
require Exporter;

use strict;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_history_widgets);

sub get_history_widgets {
    return
      ["Task History",
#        { type => 'table',
# 	 name => 'historyInfo',
# 	 values => \&get_history_data
#        }
       { type => 'tree',
	 name => 'historyInfo',
	 root => 'history',
	 parent => \&get_history_parent,
	 children => \&get_history_children,
	 expand_all => 10,
	 default => sub {
	     # XX: doesn't quite work under Gtk2 at least.
	     my ($wiz) = @_;
	     my $res;
	     $wiz->foreach_primary($wiz->{'active'},
				   sub {
				       my ($pdesc, $res, $wiz) = @_;
				       if (!$pdesc->{'done'}) {
					   $$res = $pdesc->{'name'};

					   return 'STOP';
				       }
				   }, \$res, $wiz);
	     return $res;
         }
       },
      ],
  }

sub get_history_parent {
    my ($wiz, $current) = @_;
    my $parent;
    return if ($current eq 'history');
    $wiz->foreach_primary($wiz->{'active'},
			  sub {
			      my ($pdesc, $current, $parent) = @_;
			      if ($pdesc->{'name'} eq $$current) {
				  $$parent = $pdesc->{'parent'}{'name'}
				    if (exists($pdesc->{'parent'}));
				  return 'STOP';
			      }
			  }, \$current, \$parent
			 );
    return 'history' if (!$parent);
    return $parent;
}

sub get_history_children {
    my ($wiz, $current) = @_;
    my $parent;
    my @ret;
    $wiz->foreach_primary($wiz->{'active'},
			  sub {
			      my ($pdesc, $current, $ret, $wiz) = @_;
#			      print "here: $$current\t$pdesc->{'name'}\n";
			      if ($pdesc->{'name'} eq $$current ||
				  ($$current eq 'history' && 
				   $pdesc->{'name'} eq 'topcontainer')) {
				  map { 
				      my $p = 
					$wiz->get_primary($_->{'name'});
				      push @$ret,
					{ name => $_->{'name'},
					  label => 
					  $wiz->get_value($p->{'title'} || '')
					};
				  } @{$pdesc->{'children'}};

#				  use Data::Dumper;;
#				  print Dumper($pdesc);
				  return 'STOP';
			      }
			  }, \$current, \@ret, $wiz
			 );
    return \@ret;
}

sub get_history_data {
    my ($wiz, $current, $q) = @_;
    my @names;
    my $first = 1;
    my $linewidth = 1;
    my $align = "";

    my $leftbar = "|";
    my $spacebar = " ";
    my $lastbar = "-";
    my $currentbar = ">";

    $wiz->foreach_primary($wiz->{'active'},
			  sub {
			      my ($countbars, $countspaces) = (0,0);
			      my $countall = 0;
			      my ($pdesc, $names, $wiz, $first) = @_;
			      my $x = $pdesc;
			      while(exists($x->{'parent'})) {
				  if ($x->{'parent'}{'qw_last_foreach'}) {
				      $countspaces++;
				  } else {
				      $countbars++;
				  }
				  $x = $x->{'parent'};
			      }
			      my $p = $wiz->get_primary($pdesc->{'name'});
			      my $name_str = $pdesc->{name} || "";
			      my $doc_str = $p->{documentation} || "";
			      my $title_str = $p->{title} || "";

			      if ($p && $pdesc->{'done'}) {
				  push @$names,
				    [$spacebar x ($countspaces) .
				     $leftbar x ($countbars-1) .
				     (($pdesc->{qw_last_foreach}) ? $lastbar : $currentbar) .
				     $wiz->get_value($title_str)];
			      }
			      if ($p && !$pdesc->{'done'}) {
				  my ($strs, $str);
				  ($str, $strs) = get_primary_history($wiz,$p);
				  map {
				      my $val = $wiz->get_value($_);
				      if ($$first) {
					  if ($pdesc->{'merge'}) {
					      $$first += $pdesc->{'merge'} - 1;
					  }
					  $val = "*** $val ***";
					  $$first--;
				      }
				      push @$names,
					[$spacebar x ($countspaces) .
					 $leftbar x ($countbars-1) .
					 (($pdesc->{qw_last_foreach}) ? $lastbar : $currentbar) . "$val"];
				  } @$strs;
			      }
			  }, \@names, $wiz, \$first
			 );
    return [\@names];
}

sub get_primary_history {
    my ($wiz, $p) = @_;
    my $str = $wiz->get_value($p->{'title'});
    my @results;
    push @results, $str if (defined($str));
    if ($p->{'sub_modules'}) {
	foreach my $i (@{$wiz->get_values($p->{'sub_modules'})}) {
	    my ($newstr, $newres) =
	      get_primary_history($wiz, $wiz->{'primaries'}{$i});
	    $str .= "," . $newstr;
	    push @results, @$newres;
	}
    }
    if ($p->{'sub_history'}) {
	$str .= "," . join(",",@{$wiz->get_values($p->{'sub_history'})});
	push @results, @{$wiz->get_values($p->{'sub_history'})};
    }
    return ($str, \@results);
}

1;

###########################################################################

=pod

=head1 NAME

QWizard::Plugins::History - Show a QWizard History Widget

=head1 SYNOPSIS

  use QWizard::Plugins::History;

  # add the history widget to the left side
  $qw = new QWizard(leftside => [get_history_widgets()]);

  # ...
  $qw->magic('blah');

=head1 DESCRIPTION

The history widget (best used in a sidebar) displays a list of
completed and future qwizard screen titles that are in the todo list
to finish.

=head1 AUTHOR

Wes Hardaker, hardaker@users.sourceforge.net

=head1 SEE ALSO

perl(1)

NetPolicy::module_utils(3)

http://net-policy.sourceforge.net/

=cut



