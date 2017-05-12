use strict;
use DBI;
use IO::File;

package StatsView::Oracle::Monitor;

################################################################################

sub new($$$$)
{
my ($class, $db, $fh, $rate) = @_;
$class = ref($class) || $class;
my $self = { db => $db, fh => $fh, rate => $rate };
return(bless($self, $class));
}

################################################################################

sub header($$$$$)
{
my ($self, $type, $title, $headings, $formats) = @_;
my $class = ref($self);
$class =~ s/^.*:://;
                   
$self->{fh}->print("Title:      $title\n",
                   "Statistics: $class $type\n",
                   "Headings:   $headings\n",
                   "Formats:    $formats\n\n");
}

################################################################################

sub data($$;)
{
my ($self, $timestamp, @data) = @_;
my $class = ref($self);
$class =~ s/^.*:://;
$self->{fh}->print("$class $timestamp\n", join("\n", @data), "\n\n");
}

################################################################################

sub sample($$)
{
my $self = shift;
my $class = ref($self) || $self;
die("No sample method defined for class $class\n");
}

################################################################################
1;
