# Proc-ProcessTable-Match

This provides a hand means to construct filters to use to match
with Proc::ProcessTable for matching Proc::ProcessTable::Process
objects.

    use Proc::ProcessTable::Match;
    use Proc::ProcessTable;
    use Data::Dumper;
    
    # looks for a kernel proc with the PID of 0
    my %args=(
              checks=>[
                       {
                        type=>'PID',
                        invert=>0,
                        args=>{
                               pids=>['0'],
                               }
                       },{
                        type=>'KernProc',
                        invert=>0,
                        args=>{
                               }
                      }
                      ]
                     );
    
    # hits on every proc but the idle proc
    %args=(
              checks=>[
                       {
                        type=>'Idle',
                        invert=>1,
                        args=>{
                               }
                       }
                      ]
                     );
    
    my $ppm;
    eval{
        $ppm=Proc::ProcessTable::Match->new( \%args );
    } or die "New failed with...".$@;
    
    my $pt = Proc::ProcessTable->new;
    foreach my $proc ( @{$t->table} ){
        if ( $ppm->match( $proc ) ){
            print Dumper( $proc );
        }
    }

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Proc::ProcessTable::Match
