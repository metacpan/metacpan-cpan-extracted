package Sub::Caller;

require DynaLoader;

our $VERSION = '0.60';
our @ISA = qw(DynaLoader);
bootstrap Sub::Caller;
################################
my %change;

##
## We have to delay messing with functions
## until Perl has them all loaded.
##
sub import {
   shift;
   $change{caller()} = \@_;
}

##
## Now we can mess with functions
##
sub CHECK {
   for my $k (keys %change){
      addCaller([$k], @{$change{$k}});
   }
}


my $addCaller  = sub {
   my ($CALL, $call) = ({package=>undef, function=>undef, line=>undef, file=>undef}, 0);
   my $frames = @_?shift():5;

WR_GET_CALLER_FUNC:
   $call++;
   ($CALL->{function}) = (caller $call)[3];

   ## Keep going until we find an actual function call 
   if ($CALL->{function} && $CALL->{function} =~ /ANON/ && $call < $frames){
      goto WR_GET_CALLER_FUNC;
   }
   elsif ($call < $frames){
      my ($c) = (caller ++$call)[3];
      $call-- and goto WR_GET_CALLER_FUNC if $c;
   }

   $CALL->{function}    =~ s/(.*):://;
   $CALL->{package}     = $1 || "main";
   $CALL->{function}    ||= "main";
   @$CALL{qw(file line)} = (caller(1))[1,2];

   bless $CALL;
};


sub addCaller {
   if (@_){
      my ($pkg) = ref $_[0]?shift()->[0]:caller();

      if ($_[0] =~ /all/i){
         shift;
         for my $f (keys %{$pkg."::"}){
            push @_, $f if (defined &{$pkg."::$f"} && checkFunc(\&{$pkg."::$f"}) eq $pkg);
         }
      }

      modifyCaller($pkg, @_);

      if (!defined &{$pkg."::aDdCaLLer"}){
         *{$pkg."::aDdCaLLer"} = $addCaller;
      }
   }
}


sub isCaller { ref $_[0] eq __PACKAGE__; }


sub modifyCaller {
   my ($pkg) = shift();

   for my $f (@_){
      ## Don't do anything for non-existant functions
      if (!defined(&{$pkg."::$f"})){ next; }

      ## Don't re-re-define functions else we get infinite loops
      if (defined(&{$pkg."::_$f"})){ next; }

      ## Create copy of original sub
      *{$pkg."::_$f"} = \&{$pkg."::$f"};

      ## Replace original sub with new version
      *{$pkg."::$f"} = sub {
            my $CALL = &{$pkg."::aDdCaLLer"}(2);
            ## Call original sub with caller data at end of stack 
            if ($pkg eq 'main'){
               &{$pkg."::_$f"}(@_, $CALL);
            }
            ## Make sure objects get the package name first
            else{
               &{$pkg."::_$f"}($pkg, @_[1..$#_], $CALL);
            }
      };
   }
}

1;
__END__
=pod

=head1 NAME

Sub::Caller - Add caller information to the end of @_.

=head1 DESCRIPTION

Sub::Caller provides an easy way to pass caller information to 
all, or specific, sub-routines:

   use Sub::Caller qw(all); ## Pass to all non-anon subs
   use Sub::Caller qw(sub1 sub2); ## Only these subs

   -- OR --

   use Sub::Caller;

   sub test { }

   &Sub::Caller::addCaller('test');


The sub-routines must be loaded before addCaller() can be called successfully. If you call 
addCaller() on the same sub-routine(s) multiple times, all calls after the first are silently 
ignored.

Caller information takes the form of:

   {
      package  => 'main',
      function => 'test',
      file     => 'test.pl',
      line     => 7,
   }

This hash reference is added to the end of @_.

=head1 EXAMPLE

   #!/usr/bin/perl
   # test.pl

   use Data::Dumper;
   use Sub::Caller('test');


   test('a');


   sub test {
      ## Make sure we have @_ and it is what we expect
      if (@_ && Sub::Caler::isCaller($_[-1])){
         print Dumper(\@_);
      }
   }

   __END__
   Dumper will print:

   $VAR1 = [
             'a',
             bless( {
                      'function' => 'main',
                      'file' => 'test.pl',
                      'line' => 8,
                      'package' => 'main'
                    }, 'Sub::Caller' )
           ];

=head1 AUTHOR

Shay Harding E<lt>sharding@ccbill.comE<gt>

=head1 CHANGES
   2003-05-27
      Added more tests.
      Updated POD with a clear example of usage.

=head1 TODO

Would be nice to add this to anonymous functions, but alas, I haven't figured that 
part out yet. Would probably have to dig into XS more and mess with OP code stuff.

=head1 ACKNOWLEDGEMENTS

I just want to say that Gisle Aas' "PerlGuts Illustrated" at http://gisle.aas.no/perl/illguts 
is fantastic. It really sheds some light on how all those darn SVs work out. Now if only the 
PERL_CONTEXT section were finished so I knew what those were...

