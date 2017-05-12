package Sash::Plugin::VerticalResponse::Command;

use strict;
use warnings;

# For the love of Singletons.
use base qw( Sash::Command );
use Sash::Plugin::VerticalResponse;
use Sash::Plugin::VerticalResponse::Cursor;

use Carp;

# Going straight to hell for this!
sub AUTOLOAD {
    our $AUTOLOAD;

    if ( $AUTOLOAD =~ /::(\w*)\_(meth|proc)$/ ) {
        my $args = __PACKAGE__->SUPER::_getCallerArgs ( shift, shift, $1 );
        
        # Lets allow the user to enter 3 different types of arguments:
        #
        # 1. Any previously defined variable like $x which is scoped as $Sash::Command::x.
        #    Its up to the user to get the value as a hash ref correct.
        # 2. Allow them to define an anonymous hash on the command line.
        # 3. Allow them to supply the arugments separated by commas on the command line
        #    and we create the anonymous hash.
        #
        # This handles options 1 and 2
        my $hash = __PACKAGE__->SUPER::_bringVarIntoScope( $args );
    
        # Handle option 3 if necessary.
        unless( defined $hash && ref $hash eq 'HASH' ) {
            # The coderef for the simple method.
            my $simple_method = \&{__PACKAGE__ . "::${1}_simple"};

            # Get the hash from the arguments and the simple syntax interface.
            $hash = $simple_method->( $args ) unless defined $hash && ref $hash eq 'HASH';
        }
        
        __PACKAGE__->SUPER::begin;
        
        my $cursor = Sash::Plugin::VerticalResponse::Cursor->open( { 
            query => $hash,
            caller => "${1}_meth"
        } );    
    
        my $result = $cursor->fetch;
    
        $cursor->close;
    
        return __PACKAGE__->SUPER::end( { result => $result } );
    }
    
    return "Bah! No documentation here.\n" if ( $AUTOLOAD =~ /::(\w*)_doc$/ );
    
    return "No description for $1\n" if ( $AUTOLOAD =~ /::(\w*)_desc$/ );
    
    return "No simple syntax for $1\n" if ( $AUTOLOAD =~ /::(\w*)_simple$/ );
}

sub get_command_hash {
    my $class = shift;

    my $command_hash = Sash::CommandHash->new( $class );

    my $parent_commands = $class->SUPER::get_command_hash;

    my $base_commands = {
        '' => { meth => \&Sash::Plugin::VerticalResponse::Command::default_command },
        show => $command_hash->build( { use => 'show' } ),
        refresh => { syn => 'reconnect' },
    };
    
    my @supported_methods = qw(
        addListMember
        calculateCampaignAudience
        createCompany
        createList
        createUser
        deleteList
        deleteListMember
        downloadCampaignRecipientResults
        downloadCampaignRecipientResultsBackground
        downloadList
        downloadListBackground
        editCompany
        editListAttribute
        editListMember
        editUser
        enumerateCompanies
        enumerateLists
        eraseListMembers
        getCampaignDomainCount
        getCompany
        getListDomainCount
        getListMemberByAddressHash
        getListMemberByEmailAddress
        getListMemberByHash
        getListMembers
        getUser
        getUserByEmailAddress
        renderCampaignContent
        searchListMembers
        setCustomListFields
        setDisplayedListFields
        setIndexedListFields
        validateStreetAddress
    );
    
    my $commands = { map { $_ => $command_hash->build( { use => $_, proc => 'meth' } ) } @supported_methods };

    # Give back the merged result.
    return { %{$parent_commands}, %{$base_commands}, %{$commands} }; 
}

sub calculateCampaignAudience_simple {
    return { campaign_id => shift };
}

sub createList_simple {
    my $args = shift;
    
    my @tokens = split /\W*,\W*/, $args;
    my $list_name = shift @tokens;
    my $list_type = shift @tokens;
    my $custom_field_names = [ @tokens ] if @tokens;
        
    my $hash = { name => $list_name, type => $list_type };
    $hash->{custom_field_names} = $custom_field_names if defined $custom_field_names;
    
    return $hash;
}

sub deleteList_simple {
    return { list_id => shift };
}

sub enumerateLists_simple {
    return { list_id => shift };
}

sub getCompany_simple {
    my ( $company_id, $include_users ) = split /\W*,\W*/, shift;
    return { company_id => $company_id, include_users => $include_users };
}

sub getListMembers_simple {
    return { list_id => shift, max_records => 100 };
}

sub getUser_simple {
    return { user_id => shift };
}

sub getUserByEmailAddress_simple {
    return { email_address => shift };
}

sub show_proc {
    ( my $which = shift ) =~ s/(.*?);?/$1/g;

    my $values = 'methods|username|endpoint|password';
                
    croak "usage: show $values\n" unless ( $which =~ /^$values$/ );

    if ( $which =~ /methods/ ) {
        __PACKAGE__->SUPER::begin;
    
        my $cursor = Sash::Plugin::VerticalResponse::Cursor->open( { 
            query => $which,
            caller => 'show_proc'
        } );    

        my $result = $cursor->fetch;

        $cursor->close;

        __PACKAGE__->SUPER::end( { result => $result } );
    }
    
    print Sash::Plugin::VerticalResponse->username . "\n"  if $which eq 'username';
    print Sash::Plugin::VerticalResponse->password . "\n"  if $which eq 'password';
    print Sash::Plugin::VerticalResponse->endpoint . "\n"  if $which eq 'endpoint';

    return;
}

sub default_command {
    my $term = shift;
    my $args = shift;
    
    $args->{cursor_class} = 'Sash::Plugin::VerticalResponse::Cursor';
    
    return __PACKAGE__->SUPER::default_command( $term, $args );
}


1;
