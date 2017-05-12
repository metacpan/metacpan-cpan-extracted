package Parse::CPAN::Modlist;

use strict;
use vars qw($VERSION);
use Parse::CPAN::Modlist::Module;

$VERSION = '0.9';


=pod

=head1 NAME

Parse::CPAN::Modlist - Parse 03packages.data.gz


=head1 SYNOPSIS

    use Parse::CPAN::Modlist;


    my $p = Parse::CPAN::Modlist->new("t/data/03modlist.data");


    foreach my $name ($p->modules) {
        my $module = $p->module($name);
        print " The module '".$module->name."'".
              " is written by ".$module->author.
              " and is described as '".$module->description.
              "'\n";
    }
    
=head1 DESCRIPTION

The CPAN module list is a non-comprehensive list of modules on CPAN.

Or, more exactly, it's a comprehensive list of B<registered> modules on CPAN.

http://www.cpan.org/modules/00modlist.long.html has more details.

=head1 Methods

=cut

=head2 new <filename|data>

Creates a new C<Parse::CPAN::Modlist> object and parses the data passed in.

You can either pass in the path to a (not gzipped) file or the data from an
03modlist.data file. 

=cut

sub new {
  my $class    = shift;
  my $filename = shift;


  my $self = { };
  bless $self, $class;

  $filename = '03modlist.data' if not defined $filename;

  if ($filename =~ /File:\s+03modlist.data/) {
    $self->{_details} = $filename;
  } else {
    open(IN, $filename) || die "Failed to read $filename: $!";
    $self->{_details} = join '', <IN>;
    close(IN);
  }

  $self->parse;
  return $self;
}

=head2 parse

Internal method which parses the 03modlist.data file. 

Called automatically by C<new>.

=cut



### this builds a hash reference with the structure of the cpan module tree ###
sub parse {
    my $self = shift;
    my $in   = $self->{_details};

    ### get rid of the comments and the code ###
    ### need a smarter parser, some people have this in their dslip info:
    # [
    # 'Statistics::LTU',
    # 'R',
    # 'd',
    # 'p',
    # 'O',
    # '?',
    # 'Implements Linear Threshold Units',
    # ...skipping...
    # "\x{c4}dd \x{fc}ml\x{e4}\x{fc}ts t\x{f6} \x{eb}v\x{eb}r\x{ff}th\x{ef}ng!",
    # 'BENNIE',
    # '11'
    # ],
    ### also, older versions say:
    ### $cols = [....]
    ### and newer versions say:
    ### $CPANPLUS::Modulelist::cols = [...]
    $in =~ s|.+}\s+(\$(?:CPAN::Modulelist::)?cols)|$1|s;

    ### split '$cols' and '$data' into 2 variables ###
    my ($ds_one, $ds_two) = split ';', $in, 2;

    ### eval them into existance ###
    ### still not too fond of this solution - kane ###
    my ($cols, $data);
    {   #local $@; can't use this, it's buggy -kane

        $cols = eval $ds_one;
        die "Error in eval of 03modlist.data source files: $@" if $@; 
       
        $data = eval $ds_two;
        die "Error in eval of 03modlist.data source files: $@" if $@; 
       
    }

    my $tree = {};
    my $primary = "modid";

    Parse::CPAN::Modlist::Module->mk_accessors(@$cols);

    ### this comes from CPAN::Modulelist
    ### which is in 03modlist.data.gz
    for (@$data){
        my %hash;
        @hash{@$cols} = @$_;
        $hash{'chapterid'} = int($hash{'chapterid'});
        $tree->{$hash{$primary}} = bless \%hash, 'Parse::CPAN::Modlist::Module';;
    }


    $self->{modules} = $tree;    


} 

=head2 module <module name>

Returns a C<Parse::CPAN::Modlist::Module> object representing 
the module name passed in or undef if that module is not in the 
module list.

=cut

sub module {
    my $self   = shift;
    my $module = shift;
    return $self->{modules}->{$module};
}


=head2 modules

Returns a list of the names of all modules in the module list

=cut

sub modules {
    return keys %{$_[0]->{modules}};
}


=head1 BUGS

None that I know of.

=head1 COPYING

Distributed under the same terms as Perl itself.

=head1 AUTHOR

Copyright (c) 2004, 

Simon Wistow <simon@thegestalt.org>   

based on code from C<CPANPLUS> by Jos Boumans.

=head1 SEE ALSO

L<Parse::CPAN::Packages>, L<Parse::CPAN::Authors>

=cut

1;
