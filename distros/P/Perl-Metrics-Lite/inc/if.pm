#line 1
package if;

$VERSION = '0.0606';

sub work {
  my $method = shift() ? 'import' : 'unimport';
  unless (@_ >= 2) {
    my $type = ($method eq 'import') ? 'use' : 'no';
    die "Too few arguments to '$type if' (some code returning an empty list in list context?)"
  }
  return unless shift;		# CONDITION

  my $p = $_[0];		# PACKAGE
  (my $file = "$p.pm") =~ s!::!/!g;
  require $file;		# Works even if $_[0] is a keyword (like open)
  my $m = $p->can($method);
  goto &$m if $m;
}

sub import   { shift; unshift @_, 1; goto &work }
sub unimport { shift; unshift @_, 0; goto &work }

1;
__END__

#line 113
