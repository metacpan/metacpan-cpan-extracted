package Shishi::Node;
use Shishi::Decision;
use strict;

sub new {
    my $class = shift;
    bless {
        creator => shift,
        parents => 0, 
        decisions => [],
    }, $class;
}

my %match = (
    char => sub { my ($d, $tr) = @_; my $targ = $d->{target}; $$tr =~ s/^$targ//; },
    text => sub { my ($d, $tr) = @_; my $targ = $d->{target}; $$tr =~ s/^$targ//; },
    token => sub { my ($d, $tr) = @_; my $tk = chr $d->{token}; $$tr =~ s/^$tk//; },
    any=> sub { my ($d, $tr) = @_; $$tr =~ s/.//; },
    skip=> sub { my ($d, $tr) = @_; $$tr =~ s/.//; },
    end => sub { my ($d, $tr) = @_; length $$tr == 0; },
    true => sub {1},
    code => sub { my ($d, $tr, $parser) = @_;
        print "Performing code\n" if $Shishi::Debug;
        $d->{code}->($parser, $tr);
    },
);

sub execute { 
    my $self = shift;
    my $parser = shift;
    my $match_object = shift;
    my @decs = @{$self->{decisions}};

    recurse:

    print "Executing node $self, parser is $parser, mo is $match_object\n" if $Shishi::Debug;
    for my $d (@decs) {
        my $text = $match_object->parse_text();
        print "This decision is $d\n" if $Shishi::Debug;
        my $targ = $d->{target};
        my $type = $d->{type};
        my $action = $d->{action};
        print "Trying decision $type -> $targ on $text ($d)\n" 
            if $Shishi::Debug;
        die "Unknown match type $type" unless exists $match{$type};
        next unless $match{$type}->($d, \$text, $parser); # Match
        print "$type -> $targ succeeded, action $action\n" if $Shishi::Debug;
        $match_object->parse_text($text);
        my $rc;
        if ($action == ACTION_CONTINUE) {
           # Put stuff on stack.
           print "Matched, continuing, recursing\n" if $Shishi::Debug;
           push @{$match_object->{been}}, { node => $self, text => $text, d => $d};
           $self = $d->{next_node};
           @decs = @{$self->{decisions}};
           goto recurse;
        } elsif ($action == ACTION_FINISH) {
            print "Finishing\n" if $Shishi::Debug;
           return 1;
        } elsif ($action == ACTION_FAIL) {
           print "Bailing!\n" if $Shishi::Debug;
           return -1;
        }
    }
    print "I need to pop the stack here at end\n" if $Shishi::Debug;
    if (my $pframe = pop @{$match_object->{been}}) {
        $self = $pframe->{node};
        my $text = $pframe->{text};
        $match_object->parse_text($text);
        @decs = $self->decisions;
        while (1) {
            die "Internal error: decision not found" unless @decs;
            my $x = shift @decs;
            last if $x == $pframe->{d};
        }
        goto recurse;
    }
    return 0;
}

sub add_decision {
    my $self = shift; push @{$self->{decisions}}, shift; return $self;
}

sub decisions { @{$_[0]->{decisions}} }

1;
