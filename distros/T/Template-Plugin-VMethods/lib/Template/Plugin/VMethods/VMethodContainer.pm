package Template::Plugin::VMethods::VMethodContainer;

sub new
{
  my $class = shift;
  my $this = bless {}, $class;

  # what was this thing called?
  $this->{op}        = shift;
  $this->{vmethname} = shift;

  # remember the stringification of the stash as an indentifier
  my $stash          = shift;
  $this->{stash}     = "$stash";  # stringify object ref

  # what are we replacing?
  $this->{sub}       = shift;

  return $this;
}

# this function is used to work out if the passed stash is the
# same stash that we were created in or a clone stash.  It does
# this by comparing the stringification of the ref
sub stashmatch
{
  my $this = shift;
  my $stash = shift;
  return "$stash" eq $this->{stash};
}

sub DESTROY
{
  my $this = shift;

  #print STDERR "DESTROYING $this->{op} $this->{vmethname}!\n";

  no strict 'refs';

  # work out where we're uninstalling to
  my $hashref = ${'Template::Stash::'.$this->{op}};

  # replace the vmethod with what was there before.
  if (defined($this->{sub}))
    { $hashref->{ $this->{vmethname} } = $this->{sub}; }
  else
    { delete $hashref->{ $this->{vmethname} }; }
}

1;
