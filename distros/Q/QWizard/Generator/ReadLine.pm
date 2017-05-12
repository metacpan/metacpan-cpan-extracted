package QWizard::Generator::ReadLine;

use Term::ReadLine;
require Exporter;
use QWizard::Generator;

use strict;
our $VERSION = '3.15';

@QWizard::Generator::ReadLine::ISA = qw(Exporter QWizard::Generator);

our %defaults = ();

our $width = 78;

#our $clear_screen = `clear`;  # not ideal, but hey.  (see perlfaq8)
our $clear_screen = "\n\n";

sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my %self = %defaults;
    my $self = \%self;
    $self->{'term'} = new Term::ReadLine "QWizard::ReadLine";
    bless($self, $class);
    $self->add_handler('text',\&QWizard::Generator::ReadLine::do_entry,
		       [['single','name'],
			['default']]);
    $self->add_handler('checkbox',\&QWizard::Generator::ReadLine::do_checkbox,
		       [['multi','values'],
			['default'],
			['single', 'name']]);
    $self->add_handler('label',\&QWizard::Generator::ReadLine::do_label,
		       [['multi','values']]);
    $self->add_handler('paragraph',\&QWizard::Generator::ReadLine::do_label,
		       [['multi','values']]);
    $self->add_handler('multi_checkbox',
		       \&QWizard::Generator::ReadLine::do_multicheckbox,
		       [['multi','default'],
			['values,labels']]);
    $self->add_handler('radio',
		       \&QWizard::Generator::ReadLine::do_radio,
		       [['values,labels', "   "],
			['default'],
			['single','name']]);
    $self->add_handler('textbox',\&QWizard::Generator::ReadLine::do_textbox,
		       [['single','name'],
			['default'],
			['single','size'],
			['single','maxsize'],
			['single','submit']]);
    # reuse a radio since they're the same
    $self->add_handler('menu',
		       \&QWizard::Generator::ReadLine::do_radio,
		       [['values,labels', "   "],
			['default'],
			['single','name']]);
    # pick a entry box for a file upload.  Not quite right, but...
    $self->add_handler('fileupload',
		       \&QWizard::Generator::ReadLine::do_entry,
		       [['default','values']]);
    $self->add_handler('unknown',\&QWizard::Generator::ReadLine::do_unknown,
		       []);
    $self->init_default_storage();
    return $self;
}

sub init_screen {
    my ($self, $wiz, $title) = @_;

    print $clear_screen;
    barrier("*");
    maybechompp($title," -- ", " --");
}

sub wait_for {
    barrier("-");
}

sub do_question {
    my ($self, $q, $wiz, $p, $text, $qcount) = @_;

    chompp($text);
}

sub do_question_end {
    print "\n";
}

sub start_questions {
    my ($self, $wiz, $p, $title, $intro) = @_;
    barrier("=");
    maybechompp("$title", "title: ");
    maybechompp($intro);
    print "\n";
}

sub end_questions {
    $_[0]->install_tempvars();
}

sub do_entry {
    my ($self, $q, $wiz, $p, $name, $def) = @_;
    $self->read_it($q, $name, $def);
}

sub do_error {
    my ($self, $q, $wiz, $p, $err) = @_;
    print "ERROR: $err\n";
}

sub do_textbox {
    my ($self, $q, $wiz, $p, $name, $def) = @_;

    my ($text, $val);

    print "Enter text below.  Enter a '.' on a line by itself to finish.\n";
    do {
	$text .= $val . "\n";
	$val = $self->{'term'}->readline(": ");
    } while ($val ne '.');
    chomp($text);
    $self->qwtemp($q->{'name'}, $text);
}

sub do_yn {
    my ($self, $def) = @_;
    my $val = '';
    do {
	$val = $self->{'term'}->readline("y/n" . (($def) ? " [$def]" : "")
					 . ": ");
	if ($val eq '' && $def) {
	    $val = $def;
	} elsif ($val ne 'y' && $val ne 'n') {
	    print "*** illegal answer.  You must pick 'y' or 'n'\n";
	}
    } while ($val ne 'y' && $val ne 'n');
    return $val;
}

sub get_yn_default {
    my ($def, $vals) = @_;
    my $val;
    if ($def && $def eq $vals->[0]) {
	$val = 'y';
    } else { # lets just assume a default of n for easy entry
	$val = 'n';	
    }
    return $val;
}

sub do_checkbox {
    my ($self, $q, $wiz, $p, $vals, $def, $name) = @_;
    my $val = '';
    $vals = [1,0] if ($#$vals == -1);
    $val = $self->do_yn(get_yn_default($def, $vals));
    if ($val eq 'y') {
	$self->qwtemp($name, $vals->[0]);
    } elsif ($val eq 'n') {
	$self->qwtemp($name, $vals->[1]);
    }
}

sub do_multicheckbox {
    my ($self, $q, $wiz, $p, $defs, $vals, $labels) = @_;
    my $count = -1;
    foreach my $v (@$vals) {
	$count++;
	my $l = (($labels->{$v}) ? $labels->{$v} : "$v");
	print $l,"\n";
	my $val = $self->do_yn(get_yn_default($defs->[$count], [$v,'']));
	if ($val eq 'y') {
	    $self->qwtemp($q->{name} . $v, $vals->[$count]);
	} else {
	    $self->qwtemp($q->{name} . $v, '');
	}
	push @{$wiz->{'passvars'}},$q->{'name'} . $v;
    }
}

sub do_radio {
    my ($self, $q, $wiz, $p, $vals, $labels, $def) = @_;
    my $count = 0;
    my $defcount;
    foreach my $v (@$vals) {
	$count++;
	my $text = (($labels->{$v}) ? $labels->{$v} : "$v");
	if ($def eq $v) {
	    $defcount = $count;
	}
	printf "  %3d)  %s\n", $count, $text;
    }
    my $val;
    while ($val !~ /^\d+$/ || $val-1 < 0 || $val-1 > $#$vals) {
	if ($val ne '') {
	    print "*** illegal answer\n";
	}
	$val = $self->{'term'}->readline("Pick one" .
					 (($defcount) ? " [$defcount]" : "") .
					 ": ");
	$val = $defcount if ($val eq '')
    }
    $self->qwtemp($q->{name}, $vals->[$val-1]);
}

sub do_label {
    my ($self, $q, $wiz, $p, $vals, $def) = @_;
    if (defined ($vals)) {
	map { chompp($_); }@$vals;
    }
}

sub do_menu {
    $_[0]->do_radio(@_);
}

sub do_separator {
    my ($self, $q, $wiz, $p, $text) = @_;
    print "$text\n";
}

sub do_unknown {
    my ($self, $q, $wiz, $p) = @_;

    print "Error: Unhandled question type '$q->{type}' in primary '$p->{module_name}'.\nIt is highly likely that this page will not function properly after this point.\n";
}

sub read_it {
    my ($self, $q, $name, $def, $prompt) = @_;
    my $val = $self->{'term'}->readline($prompt || 
					((($def)?"[$def] ":"") . ": "));
    if ($val eq '' && $def) {
	$self->qwtemp($name, $def);
    } else {
	$self->qwtemp($name, $val);
    }
}

##################################################
# action confirm
##################################################

sub start_confirm {
    my ($self, $wiz) = @_;

    barrier("*");
    print "Wrapping up:\n";
    print "Do you want to commit the following changes:\n";
}

sub end_confirm {
    my ($self, $wiz) = @_;
    my $val = $self->do_yn();
    if ($val eq 'y') {
	$self->qwparam('wiz_confirmed','Commit');
    } else {
	$self->qwparam('wiz_confirmed','Cancel');
    }
}

sub do_confirm_message {
    my ($self, $wiz, $msg) = @_;
    chompp($msg, "  ");
}

sub canceled_confirm {
    print "*** cancelled\n";
}

##################################################
# actions
##################################################

sub start_actions {
    my ($self, $wiz) = @_;
    barrier("*");
    print "Processing your request...\n";
}
sub end_actions {
    my ($self, $wiz) = @_;
    print "Done!\n";
}
sub do_action_output {
    my ($self, $wiz, $action) = @_;
    chompp("$action", "  ");
}
sub do_action_error {
    my ($self, $wiz, $errstr) = @_;
    chompp("$errstr", "ERROR: ");
}

##################################################
# utils
##################################################

sub chompp {
    my ($text, $prefix, $suffix) = shift;
    chomp($text);
    print $prefix, $text, $suffix,"\n";
}

sub maybechompp {
    return if (!$_[0]);
    chompp(@_);
}

sub barrier {
    print $_[0] x $width, "\n";
}

## we have a temporary storage that we fill in later into the master storage.

our %tempvars;

sub qwtemp {
    my ($self, $name, $val) = @_;
    $tempvars{$name} = $val;
}

sub install_tempvars {
    my $self = shift;
    foreach my $k (keys(%tempvars)) {
	$self->qwparam($k, $tempvars{$k});
    }
    %tempvars = ();
}

1;
