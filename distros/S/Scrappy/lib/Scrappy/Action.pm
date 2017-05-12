package Scrappy::Action;

BEGIN {
    $Scrappy::Action::VERSION = '0.94112090';
}

use Moose;
use File::Find::Rule;

# return a list of installed actions
#has actions => (
#    is      => 'ro',
#    isa     => 'ArrayRef',
#    default => sub {
#        []
#    }
#);

# a hash list of installed actions
has registry => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        my $actions = {};
        foreach my $action (@{shift->actions}) {
            $actions->{$action} = $action;
            $actions->{lc($action)} = $action;
        }
        return $actions;
    }
);

sub actions {
    my @actions = ();

    my @files =
      File::Find::Rule->file()->name('*.pm')
      ->in(map {"$_/Scrappy/Action"} @INC);

    my %actions =
      map { $_ => 1 }
      map { s/.*(Scrappy[\\\/]Action[\\\/].*\.pm)/$1/; $_ } @files;  #uniquenes

    for my $action (keys %actions) {

        my ($plug) = $action =~ /(Scrappy[\\\/]Action[\\\/].*)\.pm/;

        if ($plug) {
            $plug =~ s/\//::/g;
            push @actions, $plug;
        }

    }

    return [@actions];
}

sub load_action {
    my $self   = shift;
    my $action = shift;

    unless ($action =~ /^Scrappy::Action::/) {

        # make fully-quaified action name
        $action = ucfirst $action;

        $action = join("::", map(ucfirst, split '-', $action))
          if $action =~ /\-/;
        $action = join("", map(ucfirst, split '_', $action))
          if $action =~ /\_/;

        $action = "Scrappy::Action::$action";
    }

    # check for a direct match
    if ($self->registry->{$action}) {
        return $self->registry->{$action};
    }

    # last resort seek
    elsif ($self->registry->{lc($action)}) {
        return $self->registry->{lc($action)};
    }

    return 0;
}

# execute an action from the cli
sub execute {
    my ($class, $action_class, $action, @options) = @_;
    my $self = ref $class ? $class : $class->new;

    # show help on syntax error
    if (!$action_class || $action_class eq 'help') {

        with 'Scrappy::Action::Help';
        print $self->menu;
        print "\n";
        exit;

    }
    else {
        if ($action) {
            if (   $action eq 'meta'
                || $action eq 'registry'
                || $action eq 'actions'
                || $action eq 'load_action'
                || $action eq 'execute')
            {

                with 'Scrappy::Action::Help';
                print $self->menu;
                print "\n";
                exit;
            }
        }
    }

    # locate the action if installed
    my $requested_action = $self->load_action($action_class);

    if ($requested_action) {

        # load the desired action class
        with $requested_action;

        # is actoin available
        unless ($action) {
            print $self->help($requested_action);
            print "\n";
            exit;
        }

        # run the requested action
        print $self->meta->has_method($action)
          ? $self->$action(@options)
          : $self->help($requested_action);
        print "\n";
    }
    else {

        # ... or display the help menu
        with 'Scrappy::Action::Help';
        print $self->menu;
        print "\n";
    }
}

1;
