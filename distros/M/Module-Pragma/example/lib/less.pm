package
	less;
use strict;

our $VERSION = '2.00';

use Module::Pragma;
our @ISA = qw(Module::Pragma);

__PACKAGE__->register_tags(qw(please CPU memory fat));

sub default_import{
	return 'please';
}

sub unknown_tag{
	my($class, $tag) = @_;
	return $class->register_tags($tag);
}

sub of{
	my $class = shift;
	$class->enabled(@_);
}

1;

__END__

=head1 NAME

less - perl pragma to request less of something

=head1 SYNOPSIS

    use less 'CPU';

=head1 DESCRIPTION

This is a user-pragma. If you're very lucky some code you're using
will know that you asked for less CPU usage or ram or fat or... we
just can't know. Consult your documentation on everything you're
currently using.

For general suggestions, try requesting C<CPU> or C<memory>.

    use less 'memory';
    use less 'CPU';
    use less 'fat';

If you ask for nothing in particular, you'll be asking for C<less
'please'>.

    use less 'please';

=head1 FOR MODULE AUTHORS

L<less> has been in the core as a "joke" module for ages now and it
hasn't had any real way to communicating any information to
anything. Thanks to Nicholas Clark we have user pragmas (see
L<perlpragma>) and now C<less> can do something.

You can probably expect your users to be able to guess that they can
request less CPU or memory or just "less" overall.

If the user didn't specify anything, it's interpreted as having used
the C<please> tag. It's up to you to make this useful.

  # equivalent
  use less;
  use less 'please';

=head2 C<< BOOLEAN = less->enabled( FEATURE ) >>

The class method C<< less->of( NAME ) >> returns a boolean to tell you
whether your user requested less of something.

  if ( less->enabled( 'CPU' ) ) {
      ...
  }
  elsif ( less->enabled( 'memory' ) ) {

  }

=head2 C<< FEATURES = less->enabled() >>

If you don't ask for any feature, you get the list of features that
the user requested you to be nice to. This has the nice side effect
that if you don't respect anything in particular then you can just ask
for it and use it like a boolean.

  if ( less->enabled() ) {
      ...
  }
  else {
      ...
  }

=head1 CAVEATS

=over

=item This probably does nothing.

=item This works only on 5.10+

At least it's backwards compatible in not doing much.

=back

=cut
