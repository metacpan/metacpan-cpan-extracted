package QWizard::API;

use strict;

our $VERSION = '3.15';
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(qw_hidden qw_primary qw_text qw_textbox qw_checkbox qw_radio
		 qw_menu qw_label qw_paragraph qw_button);

###########################################################################
# primary
sub qw_primary {
    my $name = shift;
    my $title = shift;
    my $introduction = shift;
    my $questions = shift;
    my $post_answers = shift;
    my $actions = shift;

    return {
	    name => $name,
	    title => $title,
	    introduction => $introduction,
	    questions => $questions,
	    post_answers => $post_answers,
	    actions => $actions,
	    @_
	   };
}

###########################################################################
# Questions

# internal: qtype, name, text
sub _qw_textf {
    my $type = shift;
    my $name = shift;
    my $text = shift;
    return { type => $type,
	     name => $name,
	     text => $text,
	     @_
	   };
}

# name, text
sub qw_text {
    return _qw_textf('text',@_)
}

# name, text
sub qw_textbox {
    return _qw_textf('textbox',@_)
}

sub qw_label {
    my $text = shift;
    my $right = shift;

    return { type => 'label',
	     text => $text,
	     values => [$right],
	     @_};
}

sub qw_paragraph {
    my $text = shift;
    my $right = shift;

    return { type => 'paragraph',
	     text => $text,
	     values => [$right],
	     @_};
}


# name, text, onval, offval
sub qw_checkbox {
    my $name = shift;
    my $text = shift;
    my $onval = shift || 1;
    my $offval = shift || 0;
    return { type => 'checkbox',
	     name => $name,
	     text => $text,
	     values => [$onval, $offval],
	     @_
	   };
}

# internal: qtype, name, text, [values] | { labels }
sub _qw_choices {
    my $qtype = shift;
    my $name = shift;
    my $text = shift;
    my $vals = shift;
    my $type = 'labels';
    if (ref($vals) eq 'ARRAY') {
	$type = 'values';
    }
    return { type => $qtype,
	     name => $name,
	     text => $text,
	     $type => $vals,
	     @_
	   };
}

# name, text, [values] | { labels }
sub qw_radio {
    return _qw_choices('radio',@_)
}

# name, text, [values] | { labels }
sub qw_menu {
    return _qw_choices('menu',@_)
}

# name, value
sub qw_hidden {
    return {type => 'hidden', name => $_[0], values => $_[1], @_};
}

# name, text, clickedvalue, buttontext
sub qw_button {
    return {type => 'button', name => $_[0], text => $_[1], 
	    default => $_[2], values => $_[3],
	    @_};
}

1;
=head1 NAME

QWizard::API - Generate questions using an API.

=head1 SYNOPSIS

  use QWizard::API;

  my $primaries = 
  (
   qw_primary('aprim', 'My title', 'An introduction',
	      [ qw_text('textresult', 'Enter something'),
	        qw_checkbox('checkresult', 'display results?', 1, 0)]);
   # ...
  );

=head1 DESCRIPTION

QWizard::API is a wrapper around generating questions for use within a
QWizard question set.  Functionally, the only reason for doing this is
to use an API instead of hand-encoding HASH and ARRAY structures.  The
result might be slightly less verbose, however, since the tags can be
left off (I.E, name => 'something' becomes just 'something').

=head1 API

All of the APIs mentioned here take additional arguments at the end
which can be other hash pairs passed to the created objects beyond the
defaults that the APIs create.

=head2 Primary creation
To create a primary:
  qw_primary(name, title, introduction, [questions], [post_answers], [actions])

=head2 Widget creation

Text entry:
  qw_text(name, question text);
  qw_textbox(name, question text);

Chekboxes:
  qw_checkbox(name, question text, optional:onval, optional:offval);

Menus/radios:
  qw_menu(name, question text, [values] | {labels});
  qw_radio(name, question text, [values] | {labels});

Labels:
  qw_label(lefttext, righttext);
  qw_paragraph(lefttext, rightparagraph);

Hidden vars:
  qw_hidden(name, value);

Buttons:
  qw_button(name, question text, clicked value, button label);


=head1 TODO

OO interface.

=head1 EXPORT

  qw_primary
  qw_text
  qw_textbox
  qw_checkbox
  qw_radio
  qw_menu

=head1 AUTHOR

Wes Hardaker <hardaker@tislabs.com>

=head1 SEE ALSO

perl(1).

=cut
