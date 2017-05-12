package Plugins::Factory;

use strict;
use warnings;

our $VERSION = '0.01';

use Module::Load;
require Module::Pluggable;

# save all plugin and package
$Plugins::Factory::job_name = {};

# save all code ref
$Plugins::Factory::ref_code = {};

sub import {
    my ($class,%opts) = @_;
    my ($call_pkg) = caller;
    map {
        my $pl_name = $_;
        my $namespace = $opts{$pl_name}->{'plugin_namespace'} if exists $opts{$pl_name}->{'plugin_namespace'};
        next unless (ref $opts{$pl_name} eq 'HASH' and $namespace);
        my $method = $opts{$pl_name}->{'init_method'};
        
        Module::Pluggable->import(search_path => [$namespace]);
        foreach my $pkg (__PACKAGE__->plugins) {            
            load $pkg;
            (my $short_name = $pkg) =~ s/^${namespace}:://;
            push @{$Plugins::Factory::job_name->{$call_pkg}->{$pl_name}},$pkg;
            $Plugins::Factory::ref_code->{$call_pkg}->{$pl_name}->{$short_name} =
            $Plugins::Factory::ref_code->{$call_pkg}->{$pl_name}->{$pkg} =
            ($method and $pkg->can($method)) ? sub {$pkg->$method(@_)} : sub {$pkg};
        }
        
        no strict 'refs';
        no warnings qw(redefine prototype);
        # add function in traget package
        *{"$call_pkg\::$pl_name"} = sub {
                                             my ($class,$name,@init) = @_;                                            
                                             return $Plugins::Factory::job_name->{$call_pkg}->{$pl_name} unless $name;
                                             return $Plugins::Factory::ref_code->{$call_pkg}->{$pl_name}->{$name}->(@init) if exists $Plugins::Factory::ref_code->{$call_pkg}->{$pl_name}->{$name};
        } if exists $Plugins::Factory::ref_code->{$call_pkg}->{$pl_name};        
        use strict 'refs';
        1;
    } keys %opts;
    
}


1;
__END__

use Plugins::Factory
                    model => {
                        plugin_namespace => 'MyProject::SomePath::MyModel',
                        init_method => 'get_instance'
                    },
                    controller => {
                        plugin_namespace => 'MyProject::SomePath::MyController',
                        init_method => 'process'
                    },
                    view => {
                        plugin_namespace => 'MyProject::SomePath::SomeView',
                        init_method => 'render'
                    };
                    

=encoding utf-8

=head1 NAME

B<Plugins::Factory> - simple plugins factory.

=head1 SYNOPSIS
    
- - - - - - - - - - - - - - - - - - - -
    
    package MyProject::MyModel::News;
    # some model
    
    sub new { bless( ref $_[1] eq 'HASH' ? $_[1] : {}, $[0] ) }
    sub get_news {print $_[0]->{'news'}}
    
    1;
    
    - - - - - - - - - - - - - - - - - - - -
    
    package MyProject::MyModel::Rss;
    # some model
    use LWP;
    
    my $singletone;
    
    sub new { 
    	unless ($singletone) {
    		$singletone = LWP::UserAgent->new();
    	}
    	return $singletone;    	 
    }
    sub get_rss {...}
    
    1;
    
    - - - - - - - - - - - - - - - - - - - -

    package MyProject::MyController::Newspaper;
    # some controller
    
    sub init {__PACKAGE__}
    sub process {
    	my ($class,@param) = @_;
    	...
    }
    
    1;
    
    - - - - - - - - - - - - - - - - - - - -
    
    package MyApplication;
    # you app
    use Plugins::Factory
                    model => {
                        plugin_namespace => 'MyProject::MyModel',
                        init_method => 'new'
                    },
                    controller => {
                        plugin_namespace => 'MyProject::MyController',
                        init_method => 'init'
                    };
    
    MyApplication->model('News',{news=>'some news'})->get_news();
    # equvalent MyProject::MyModel::News->new({news=>'some news'})->get_news()
    
    MyApplication->model('MyProject::MyModel::News',{news=>'some news'})->get_news();
    # alternative call
    
    MyApplication->model('Rss')->get_rss(@param);
    # equvalent MyProject::MyModel::Rss->new()->get_rss(@param) 
    
    MyApplication->controller('Newspaper')->process(@param);
    # equvalent MyProject::MyController::Newspaper->init()->process(@param)
    
    $Plugins::Factory::job_name->model();
    # return arrayref with all full-name plugin on serch path MyProject::MyModel::*
    
=head1 DESCRIPTION

Plugins::Factory find and load your plugin and save link to initial method.
Every time, when you call plugins group alias with short (or full) plugin name, Plugins::Factory execute link to initial method. 
This is good for custom application with MVC, when you need in intuitive interface.

=head2 CALL SYNOPSIS

    use Plugins::Factory
                    name_group => {
                        plugin_namespace => 'namespace::to::group::plugin',
                        init_method => 'name_method_to_call_when_you_call_name_group'
                    },...;

alternative
    
    require Plugins::Factory;
    Plugins::Factory->import(
                    name_group => {
                        plugin_namespace => 'namespace::to::group::plugin',
                        init_method => 'name_method_to_call_when_you_call_name_group'
                    },...
    );

=head1 AUTHOR

Ivan Sivirinov

=cut
                    