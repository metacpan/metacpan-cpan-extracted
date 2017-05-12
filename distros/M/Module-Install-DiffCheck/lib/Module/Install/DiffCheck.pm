package Module::Install::DiffCheck;

=head1 NAME

Module::Install::DiffCheck - Run diff commands looking for deployment problems

=head1 SYNOPSIS

Add statements like these to your Module::Install generated Makefile.PL:

  diffcheck(
     before_diff_commands => [
        'Model/refresh_Schema.pl',
        'Model/mysqldump.pl root SuperSecret',
     ],
     diff_commands => [
        'svn diff --diff-cmd diff -x "-i -b -u" Model',
     ],
     ignore_lines => [
        qr/ *#/,              # Ignore comments
        qr/^\-\-/,            # Ignore comments
        qr/AUTO_INCREMENT/,   # These change all the time
     ],
  );

That's it. Each C<before_diff_commands> is executed, then each C<diff_commands>
is executed. Any diff output lines that don't match an C<ignore_lines> regex cause
a fatal error.

We use L<DBIx::Class::Schema::Loader>, mysqldump, and Subversion, but you should
be able to use any version control system, RDBMS, and ORM(s) that make you happy.
And/or you could diff other files that have nothing to do with databases.

=head1 DESCRIPTION

If you use a version control system to deploy your applications you might find
this module useful.

=head2 How we check our database schemas

Here, I describe the specifics of how we use this where I work, in case
you find this practical example illustrative.

We commit all our database schemas into our 
version control system. Every time we deploy a specific release it is critical that
the RDBMS schema on that server exactly matches the schema in our version control system.
New tables may have been introduced, tables may have been 
altered, or old tables may have been removed. 
diffcheck() lists all errors and dies if it detects problems.

We use both L<DBIx::Class::Schema::Loader> C<make_schema_at> and C<mysqldump>
to store our schemas to disk. We then commit those files into our Subversion
repository.

(L<DBIx::Class::Schema::Loader> C<make_schema_at> is slick. With 5 lines of code, you can 
flush an entire database into a static Schema/ directory. C<svn diff> shows us what, 
if anything, has changed.)

Similarly, C<mysqldump> output (or whatever utility dumps C<CREATE TABLE> SQL out of your
database) added to our SVN repository lets us run C<svn diff> and see everything that changed.

So, assuming the DBA has already prepped the appropriate database changes (if any) for "sometag",
our deployment goes like this:

  svn checkout https://.../MyApp/tags/sometag MyApp
  cd MyApp
  perl Makefile.PL
  make 
  make install

All done. L<Module::Install> has installed all our CPAN dependencies for us, all other custom
log directories and what-not are ready to go, and our database schema(s) have been 
audited against the tag.

If the DBA forgot to prep the database, then perl C<Makefile.PL> dies with a report about which
part(s) of the C<diff_cmd> results were considered fatal. 

This module will not help you if you want to manage your schema versions down to
individual "ALTER TABLE" statements which transform one tag to another tag. 
(Perhaps L<DBIx::Class::Schema::Versioned> could help you with that level of granularity?)
We don't get that fancy where I work.

=head1 METHODS

=cut

use strict;
use Text::Diff::Parser;
our @ISA;
require Module::Install::Base;
@ISA = qw/Module::Install::Base/;

our $VERSION = '0.02';


=head2 diffcheck

See SYNOPSIS above.

=cut

sub diffcheck {
    my ($self, %args) = @_;
    print <<EOF;
*** Module::Install::DiffCheck
EOF

    unless ($args{diff_commands}) {
       die "diffcheck() requires a diff_commands argument";
    }

    my $fatal = 0;
    if ($args{before_diff_commands}) {
       $fatal += $self->_run_before_diff_commands(\%args);
    }
    $fatal += $self->_run_diff_commands(\%args);

    if ($fatal) {
       print "*** Module::Install::DiffCheck FATAL ERRORS\n";
       exit $fatal;
    }

    print <<EOF;
*** Module::Install::DiffCheck finished.
EOF

    return 1;     # Does Module::Install care?  
}



sub _run_before_diff_commands {
   my ($self, $args) = @_;
  
   my $fatal = 0; 
   foreach my $cmd (@{$args->{before_diff_commands}}) {
      print "running '$cmd'\n";
      open(my $in, "$cmd 2>&1 |");
      while (<$in>) {
         chomp;
         print "   $_\n";
         # $fatal++;    # hmm...
      }
      close $in;
   }
   return $fatal;
}


sub _run_diff_commands {
   my ($self, $args) = @_;
 
   my $fatal = 0;
   foreach my $cmd (@{$args->{diff_commands}}) {
      print "running '$cmd'\n";
      my $diff = `$cmd`;
   
      my $parser = Text::Diff::Parser->new(
         Simplify => 1,
         Diff     => $diff,
         # Verbose  => 1,
      );
   
      foreach my $change ( $parser->changes ) {
         next unless ($change->type);    # How do blanks get in here?
         my $msg = sprintf(
            "   CHANGE DETECTED! %s %s %s line(s) at lines %s/%s:\n",
            $change->filename1,
            $change->type, 
            $change->size,
            $change->line1,
            $change->line2,
         );
         my $size = $change->size;
         my $show_change = 0;
     
         LINE:
         foreach my $line ( 0..($size-1) ) {
            # Huh... Only the new is available. Not the old?
            foreach my $i (@{$args->{ignore_lines}}) {
               next LINE if ($change->text( $line ) =~ $i);
            }
            $msg .= sprintf("      [%s]\n", $change->text( $line ));
            $show_change = 1;
            $fatal = 1;
         }
         if ($show_change) {
            # Hmm... It would be nice if we could just kick out the unidiff here?
            print $msg;
         }
      }
   }
   return $fatal;
}


=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>

=head1 BUGS

This module makes no attempt to work on Windows. Sorry. Patches welcome.

Please report any bugs or feature requests to C<bug-module-install-diffcheck at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Install-DiffCheck>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Install::DiffCheck

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Install-DiffCheck>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Install-DiffCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Install-DiffCheck>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Install-DiffCheck>

=item * Version control

L<http://github.com/jhannah/module-install-diffcheck>, 
L<http://svn.ali.as/cpan/trunk/Module-Install/lib/Module/Install/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009-2013 Jay Hannah, all rights reserved.

=cut

1; # End of Module::Install::DiffCheck

