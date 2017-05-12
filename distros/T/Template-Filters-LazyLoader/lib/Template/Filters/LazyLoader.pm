package Template::Filters::LazyLoader;

use strict;
use base qw/Class::Accessor::Fast/;
use File::Spec;
use Carp;
use Module::Recursive::Require 0.04;
use UNIVERSAL::require;

use vars qw/$VERSION/;
$VERSION = '0.05';

__PACKAGE__->mk_accessors(
    qw/
        static_filter_prefix  filters  base_pkg
        pkg pkgs dynamic_filter_prefix lib_path 
     /
);

sub load {
    my $s = shift;

    croak 'You must set base_pkg or pkg or pkgs.' if( !$s->base_pkg() && !$s->pkg && !$s->pkgs );
    
    my $recursive_args = {};
    if ( $s->lib_path() ){
        $recursive_args->{path} = $s->lib_path();
    }

    unless ( $s->static_filter_prefix() ) {
        $s->static_filter_prefix( 'fs_' );
    }
    
    unless ( $s->dynamic_filter_prefix() ) {
        $s->dynamic_filter_prefix( 'fd_' );
    }

    my $r = Module::Recursive::Require->new( $recursive_args ); 
    my @packages = () ;

    if ( $s->base_pkg() ) {
        @packages = $r->require_of( $s->base_pkg() );
    }
    elsif( $s->pkgs() ) {
        for my $pkg ( @{ $s->pkgs() } ) {
            $pkg->require() or croak $@;
        }
        @packages = @{ $s->pkgs() } ;
    }
    else {
        $s->pkg()->require() or croak $@;
        $packages[0] = $s->pkg();
    }

    no strict;
    READ_PKG_LOOP:
    for my $filter_pkg ( @packages ) {
        
        my $pkg_href = $filter_pkg . '::' ;
        READ_SUB_LOOP:
        foreach my $symbol ( keys %{ $pkg_href } ) {
            
            local *glob = $pkg_href->{$symbol} ;
            next READ_SUB_LOOP unless $symbol 
                =~ /^$s->{static_filter_prefix}|^$s->{dynamic_filter_prefix}/;
            if ( defined &glob ) {
                if ( $symbol =~ /^$s->{static_filter_prefix}/ ) {
                    $symbol =~ s/^$s->{static_filter_prefix}//;
                    $s->{filters}{ $symbol } = \&glob || undef ;
                }
                else {
                    $symbol =~ s/^$s->{dynamic_filter_prefix}//;
                    $s->{filters}{ $symbol } = [ \&glob , 1 ]|| undef ;
                }
            }
        }
    }
    return $s->{filters};
}

1;

=head1 NAME

Template::Filters::LazyLoader - Loading template filter modules by lazy way.

=head1 DESCRIPTION

Are you lazy? If so you come to right place :-) . This module load all your
nice and sexy custom template filter modules with very simple and lazy way.

What you need to do is set parent package and then, LazyLoader read all
packages recursively under the parent package and read all filter modules 
automatically from those packages.

=head1 SYNOPSYS

    my $lazy = Template::Filters::LazyLoader->new();

    # You must use base_pkg or pkg , do not use both.

    # Case using base_pkg
    # read all packages which using My::Custom::Filters as base module .
    # e.g. ( My::Custom::Filters::One , My::Custom::Filters::Two , # My::Custom::Filters::A::Three ... )
    $lazy->base_pkg('My::Custom::Filters'); 

    # case using pkg
    # read My::Custom::Filter package only.
    $lazy->pkg( 'My::Custom::Filter');
   
    # case using pkgs
    $lazy->pkgs( [qw/My::Filter1 My::Filter2/] );

    # below methods are optional. I never use it.
    #$lazy->static_filter_prefix( 'fs_' ); # default is fs_
    #$laxy->dynamic_filter_prefix( fd_' ); # default is fd_
    #$lazy->lib_path( '/path/to/your/lib') # default is $INC[0]
    
    my $tt = Template->new( { FILTERS => $lazy->load() );
    
    # $lazy->filters(); 
    

Your one filter package.

    package Your::Filter::OK;
    
    sub fs_foo {
        return 'foo';
    }
    
    sub fd_boo {
        sub {
            return 'boo';
        }
    }

Your template

 [% 'I never show up | foo %]
 [% FILTER boo( 1,32,4,3) %]
  orz
 [% END %]
 


=head1 SET BASE PACKAGE

This is the example where you put your filter package. 

Suppose you set base_pkg as 'CustomFilters' and you have below lib tree.

 |-- lib
 |   |-- CustomFilters
 |   |   |-- Osaka.pm
 |   |   |-- Seattle.pm
 |   |   `-- USA
 |   |       `-- Okurahoma.pm
 |   |-- CustomFilters.pm
 |   `-- NeverCalled.pm
 

LazyLoader only read under CustomFilters dir recursively means it does not read CustomFilters.pm and NeverCalled.pm 

=head1 SET PREFIX

You must read 'Configuration - Plugins and Filters'  SECTION for Template Tool
Document first. 

OK now you know there are 2 types of filter which are static and dynamic. To
distinct between this , LazyLoader ask you to set prefix for your all filter
methods. for static you should start your method with 'fs_' and for dynamic
'fd_'. You can also change this prefix with static_filter_prefix ,
dynamic_filter_prefix methods if you want.

 sub fs_foo{ 
    return 'foo';
 }
 
 sub fd_bar{
    return sub {
        return 'bar';
    }
 }
 
 sub never_loaded {
    return "This module never read by LazyLoader";
 }

=head1  NAMING RULE

There is very important rule to use LazyLoader. Method name must be unique
even different package.

 sub {prefix}must_unique_name {
 
 }

=head1 METHOD

=head2 base_pkg

set your parent package!!!

=head2 pkg

set your package which contain filter modules.

=head2 pkgs

set your pakcages as array ref.

=head2 load

Load your filter modules and return filters hash ref.

=head2 filters

return filters hash ref. You must use this after calling load() method.

=head2 static_filter_prefix

You can set static filter prefix if you want. default is 'fs_'

=head2 dynamic_filter_prefix

You can set dynamic filter prefix if you want. default is 'fd_'

=head2 lib_path

You can set lib path if you want. default if $INC[0] SEE
C<Module::Recursive::Require> 

=head1 SEE ALSO

Template , Class::Accessor::Fast , Module::Recursive::Require 

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi+cpan@gmail.com>

=head1 COPYRIGHT

This program is distributed under the Artistic License

=cut
