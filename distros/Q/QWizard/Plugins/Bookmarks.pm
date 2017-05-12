package QWizard::Plugins::Bookmarks;

our $VERSION = '3.15';
require Exporter;

use strict;
use QWizard;
use QWizard::API;
use QWizard::Storage::File;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(init_bookmarks);

our $marks;

our $memory_mark = '__memory_mark';
our $memory_mark_modified = '__memory_mark_modified';

sub get_bookmark_list {
    my $qw = shift;
    my @list = ($qw->{'__bookmarks_params'}{'title'},
		$qw->{'__bookmarks_params'}{'saveopt'});
    my $all = $marks->get_all();
    push @list, (grep { $_ !~ /^__/ } keys(%$all));
    return \@list;
}


#
# this function is called at the top of a page and if the user had hit
# the 'save' equivelent menu item then it jumps to the primary to
# request a name.
#
sub bookmarks_start_page_begin {
    my ($qw) = @_;
    return if ($qw->qwpref('qw_nobookmarks'));
    if ($qw->qwparam('qwbookmarks') ne $qw->{'__bookmarks_params'}{'title'}) {
	if ($qw->qwparam('qwbookmarks') eq 
	    $qw->{'__bookmarks_params'}{'saveopt'}) {
	    if (!$qw->qwparam('bookmark_name')) {
		$qw->add_todos('get_bookmark_name');
	    }
	}
    }
}

#
# this function is called right at the beginning of the keep_working
# qwizard loop.
#
#  1) if we got here after entering a save name save the data under
#     the bookmark_name parameter setting and then restore the screen
#     to just before they hit the 'save' button.
#
#  2) If they hit the menu to load a bookmark, load that data
#
#  3) else (!2) save the current spot into the special $memory_mark slot.
#
sub bookmarks_keep_working_begin {
    my ($qw) = @_;

    return if ($qw->qwpref('qw_nobookmarks'));
    if ($qw->qwparam('bookmark_name')) {
	#
	# memorize the page the user was looking at
	#   Note: which is different than where we are now
	#
	my $usemodified = $qw->qwparam('qwbm_use_modified');
	my $str = $marks->get($usemodified ?
			      $memory_mark_modified : $memory_mark);
	$marks->set($qw->qwparam('bookmark_name'), $str);

	# after saving it, reset to that point to continue on
	bookmarks_jump_to_string($qw, $str);
    }
    if ($qw->qwparam('qwbookmarks') ne $qw->{'__bookmarks_params'}{'title'}) {
	if ($qw->qwparam('qwbookmarks') ne 
	    $qw->{'__bookmarks_params'}{'saveopt'}) {

	    # Get the requested book mark data
	    my $str = $marks->get($qw->qwparam('qwbookmarks'));

	    # Jump to it
	    bookmarks_jump_to_string($qw, $str);
	}
    } else {
	# save the current QWizard history spot for use later if they
	# do bookmark this page.
	my $str = $qw->{'generator'}{'datastore'}->to_string();
	$marks->set($memory_mark, $str);
    }
}

sub bookmarks_jump_to_string {
    my ($qw, $str) = @_;

    my $store = $qw->{'generator'}{'datastore'};

    $store->from_string($str);

    if ($store->get('qwbookmarks') ne $qw->{'__bookmarks_params'}{'title'}) {
	# we need to refresh the current screen instead of
	# 'submitting' to the next one.
	$store->set('redo_screen',1);

	# We need to change the value of the bookmark menu back to
	# its default so we don't trigger any other code.
	$store->set('qwbookmarks',
		    $qw->{'__bookmarks_params'}{'title'});
    }
}


#
# call for end_sections_hook
#
sub bookmarks_end_section_hook {
    my ($qw, $p) = @_;
    $p = $p->[0];
    return if ($p->{'title'} eq 'Remember This Spot');
    my $str = $qw->{'generator'}{'datastore'}->to_string();
    $marks->set($memory_mark_modified, $str);
}

sub init_bookmarks {
    my ($qw, $storage, %params) = @_;

    our @questions =
      (
       { type => 'menu', name => 'qwbookmarks',
	 values => \&get_bookmark_list,
	 submit => 1,
	 default => $params{'title'} || 'Bookmarks', override => 1},
      );

    our %bookmark_primaries =
      (
       get_bookmark_name =>
       { title => 'Remember This Spot',
	 questions =>
	 [qw_text('bookmark_name', "Name to remember it by:", 
		  check_value => \&QWizard::qw_required_field),
	  qw_checkbox('qwbm_use_modified',
		      "Use Page Settings Including Changes",
		      1, 0,
		      default => 1,
		      helpdesc => '(otherwise save the page before modifications were made to it)')],
       }
      );


    $qw->{'__bookmarks_params'} = \%params;
    $qw->{'__bookmarks_params'}{'title'} = 'Bookmarks' 
      unless (exists($qw->{'__bookmarks_params'}{'title'}));
    $qw->{'__bookmarks_params'}{'saveopt'} = 'Remember This Page' 
      unless (exists($qw->{'__bookmarks_params'}{'saveopt'}));
    $marks = $storage;
    push @{$qw->{'topbar'}},@questions;
    $qw->add_hook('start_page_begin', \&bookmarks_start_page_begin);
    $qw->add_hook('keep_working_begin', \&bookmarks_keep_working_begin);
    $qw->add_hook('end_section', \&bookmarks_end_section_hook);
    $qw->merge_primaries(\%bookmark_primaries);
}

=pod

=head1 NAME

QWizard::Plugins::Bookmarks - Adds a bookmark menu to QWizard based applications
answers.

=head1 SYNOPSIS

  use QWizard;
  use QWizard::Storage::File;
  use QWizard::Plugins::Bookmarks;

  my $qw = new QWizard( ... );
  my $storage = new QWizard::Stoarge::File(file => "/path/to/file");
  init_bookmarks($qw, $storage, OPTIONS);

=head1 DESCRIPTION

This module simply adds in a menu at the top of all QWizard screens to
create and, display and jump to bookmarks.  The bookmarks_init
function needs access to the already created qwizard object and a
QWizard storage container (SQL or File based ones, for example, work
well).

The bookmarks will not be shown if the qw_nobookmarks preference is
set to a true value.

=head1 OPTIONS

The options parameter of the init_bookmarks() function allows you to
set I<name> => I<value> value pairs of options.  The following are
currently supported:

=over

=item I<title> => I<"Bookmarks">

The title parameter lets you override the default menu name from
"Bookmarks" to a title of your choice.

=item I<saveopt> => I<"Remember This Page">

The option name that used used as the "save this spot" kind of value.

=back

=head1 AUTHOR

Wes Hardaker, hardaker@users.sourceforge.net

=head1 SEE ALSO

perl(1)

Net-Policy: http://net-policy.sourceforge.net/

=cut

1;
