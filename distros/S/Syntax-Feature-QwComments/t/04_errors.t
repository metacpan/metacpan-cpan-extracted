use strict;
use warnings;

use Test::More tests => 21;

my @warnings;
BEGIN {
   $SIG{__WARN__} = sub {
      push @warnings, $_[0];
   };
}

use syntax qw( qw_comments );

my $error;
my @a;

my $eerror;
my @ewarnings;
my @ea;

{
   no syntax qw( qw_comments );
   eval 'qw';
   $eerror = "".$@;
   $eerror =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   $eerror =~ s/string(?= terminator)/qw/s;
} {   
   use syntax qw( qw_comments );
   eval 'qw';
   $error = "".$@;
   $error =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   ok($eerror, "Missing start delimiter test verification");
   is($error, $eerror, "Missing start delimiter");
}

{
   no syntax qw( qw_comments );
   eval 'qw!';
   $eerror = "".$@;
   $eerror =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   $eerror =~ s/string(?= terminator)/qw/s;
} {   
   use syntax qw( qw_comments );
   eval 'qw!';
   $error = "".$@;
   $error =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   ok($eerror, "Missing delimiter test verification");
   is($error, $eerror, "Missing terminator");
}

{
   no syntax qw( qw_comments );
   eval "qw'";
   $eerror = "".$@;
   $eerror =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   $eerror =~ s/string(?= terminator)/qw/s;
} {   
   use syntax qw( qw_comments );
   eval "qw'";
   $error = "".$@;
   $error =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   ok($eerror, "Missing delimiter test verification");
   is($error, $eerror, "Missing terminator");
}

{
   no syntax qw( qw_comments );
   eval "qw\x07";
   $eerror = "".$@;
   $eerror =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   $eerror =~ s/string(?= terminator)/qw/s;
} {   
   use syntax qw( qw_comments );
   eval "qw\x07";
   $error = "".$@;
   $error =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   ok($eerror, "Missing delimiter test verification");
   is($error, $eerror, "Missing terminator");
}

{
   no syntax qw( qw_comments );
   eval 'qw( ( )';
   $eerror = "".$@;
   $eerror =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   $eerror =~ s/string(?= terminator)/qw/s;
} {   
   use syntax qw( qw_comments );
   eval 'qw( ( )';
   $error = "".$@;
   $error =~ s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s;
   ok($eerror, "Missing nested delimiter test verification");
   is($error, $eerror, "Missing nested terminator");
}

{
   no syntax qw( qw_comments );
   eval '@a = qw( a, b ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   @ewarnings = @warnings;
   @ea = @a;
   @warnings = ();
} {   
   use syntax qw( qw_comments );
   eval '@a = qw( a, b ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   ok(0+@warnings, "One comma warning test verification");
   is_deeply(\@warnings, \@ewarnings, "One comma warnings");
   is_deeply(\@a, \@ea, "One comma result");
   @warnings = ();
}

{
   no syntax qw( qw_comments );
   eval '@a = qw( a, b, ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   @ewarnings = @warnings;
   @ea = @a;
   @warnings = ();
} {   
   use syntax qw( qw_comments );
   eval '@a = qw( a, b, ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   ok(0+@warnings, "Two commas warning test verification");
   is_deeply(\@warnings, \@ewarnings, "Two commas warnings");
   is_deeply(\@a, \@ea, "Two commas result");
   @warnings = ();
}

{
   no syntax qw( qw_comments );
   eval 'qw( ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   @ewarnings = @warnings;
   @warnings = ();
} {   
   use syntax qw( qw_comments );
   eval 'qw( ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   is_deeply(\@warnings, \@ewarnings, "Zero elements in void context");
   @warnings = ();
}

{
   no syntax qw( qw_comments );
   eval 'qw( a ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   @ewarnings = @warnings;
   @warnings = ();
} {   
   use syntax qw( qw_comments );
   eval 'qw( a ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   ok(0+@warnings, "One element in void context test verification");
   is_deeply(\@warnings, \@ewarnings, "One element in void context");
   @warnings = ();
}

{
   no syntax qw( qw_comments );
   eval 'qw( a b ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   @ewarnings = @warnings;
   @warnings = ();
} {   
   use syntax qw( qw_comments );
   eval 'qw( a b ); 1' or do { my $e = $@; chomp($e); die $e; };
   s/ at (?:(?!\bat\b).)+ line \S+\.\n\z//s for @warnings;
   ok(0+@warnings, "Two elements in void context test verification");
   is_deeply(\@warnings, \@ewarnings, "Two elements in void context");
   @warnings = ();
}

1;
