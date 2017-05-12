
package Sendmail::AccessDB;
#use DB_File;
use BerkeleyDB;
use strict;
use Carp;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS 
		     $sub_regex_lock $DB_FILE);
	$VERSION     = 1.04;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw (spam_friend whitelisted lookup);
	%EXPORT_TAGS = ();
	$DB_FILE = '/etc/mail/access.db';
}

=head1 NAME

Sendmail::AccessDB - An interface to the Sendmail access.db list

=head1 SYNOPSIS

 use Sendmail::AccessDB qw(spam_friend whitelisted);
 $friend_or_hater = spam_friend('user@example.com');
 $whitelisted = whitelisted('sender@example.com');

=head1 DESCRIPTION

This module is designed so that users of the Sendmail::Milter module (or
other Sendmail programmers) can ascertain if a user has elected to whitelist
themselves as a "spam friend" (where there should be no spam filtering on 
mail to them) or, where spam-filtering is not the default, but an option, where
certain receipients have been labeled as "spam haters"

=head1 USAGE

 use Sendmail::AccessDB qw(spam_friend);
 $friend_or_hater = spam_friend('user@example.com');

Ordinarily, this will look for such things as "Spam:user@example.com", 
"Spam:user@", etc., in the /etc/mail/access.db file. There is an optional
second argument "Category", which could be used if you wanted to enable 
specific checks, for example, if you wanted to customize down to a per-check
basis, you might use:

 $rbl_friend_or_hater = spam_friend('user@example.com',
                                    'qualifier' => 'maps_rbl'); 
 $dul_friend_or_hater = spam_friend('user@example.com',
                                    'qualifier' => 'maps_dul'); 

Caution should be taken when defining your own categories, as they may
inadvertantly conflict with Sendmail-defined categories.

 use Sendmail::AccessDB qw(whitelisted);
 $whitelisted = whitelisted('sender@example.com');
 $whitelisted_host = whitelisted('foo.example.com');
 $whitelisted_addr = whitelisted('192.168.1.123');

Would check for appropriate whitelisting entries in access.db. Some lookups
might be ambiguous, for example:

 $whitelisted = whitelisted('foobar');

where it is hard to know if that is supposed to be a hostname, or a sender.
whitelisted() accepts the 'type' argument, such as:

 $whitelisted = whitelisted('foobar','type'=>'hostname');
 $whitelisted = whitelisted('postmaster','type'=>'mail');

It's also possible to feed the qualifier argument, if necessary, for example,
to do:
 
 $whitelisted = whitelisted('host.example.com','type'=>'hostname',
                            'qualifier' => 'Connect');

which would check to see if this host has an OK flag set for the Connect
qualifier.

There is also the generic "lookup", which, at its simplest, takes a single
argument:

 $rc = lookup('host.example.com');

will do a lookup on host.example.com. But if you wanted to pay attention to
parent-domains, you might do:

 $rc = lookup('host.example.com', 'type'=>'hostname');

but if you wanted to find out if 'host.example.com', or any of its parent 
domains ('example.com' and 'com'), had a value in the "MyQual" qualifier, you
might do:

 $rc = lookup('host.example.com','type'=>'hostname','qualifier'=>'MyQual');

which would look up, in order 'MyQual:host.example.com', 'MyQual:example.com',
and 'MyQual:com', returning the first (most specific) one found.

=head1 BUGS

None that I've found yet, but I'm sure they're there.

=head1 SUPPORT

Feel free to email me at <dredd@megacity.org>

=head1 AUTHOR

	Derek J. Balling
	CPAN ID: DREDD
	dredd@megacity.org
	http://www.megacity.org/software.html

=head1 COPYRIGHT

Copyright (c) 2001 Derek J. Balling. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=head1 PUBLIC METHODS

Each public function/method is described here.
These are how you should interact with this module.

=cut


=head2 spam_friend

 Usage     : $friend_or_hater = spam_friend($recipient,
                                            ['qualifier' => $category])
 Purpose   : Consults the /etc/mail/access.db to check for spamfriendliness
 Returns   : 'FRIEND','HATER', or undef (which would mean default 
             behavior for that site)
 Argument  : The recipient e-mail address and an optional qualifier if
             the default of 'Spam' is not desired. 
 Throws    : 
 Comments  : 
 See Also  : 

=cut

sub spam_friend
{
    my $address = shift;
    my $qual = shift || 'Spam';
    return lookup($address,'qualifier'=>$qual,'type'=>'mail');
}

=head2 whitelisted

 Usage     : whitelisted($value)
 Purpose   : Determine if an e-mail address, hostname, or IP address is
             explicitly whitelisted, in that it contains an "OK" or "RELAY"
             value in the database.
 Returns   : 0/1, true or false as to whether the argument is whitelisted
 Argument  : Either an email-address (e.g., foo@example.com), an IP address
             (e.g., 10.200.1.230), or a hostname (e.g., mailhost.example.com)
             as well as 'type' and 'qualifer' arguments (see lookup for greater
             detail)
 Throws    : 
 Comments  : The code makes a pretty good attempt to figure out what type
             of argument $value is, but it can be overriden using the 'type'
             qualifier.
See Also   : 

=cut

sub whitelisted
{
    my $address = shift;
    my %args = @_;
    
    if (! defined $args{'type'})
    {
        if ($address =~ /\@/)
        {
	    $args{'type'} = 'mail';
        }
        elsif ($address =~ /^(?:\d+\.){3}\d+/)
        {
	    $args{'type'} = 'ip';
        }       
        elsif ($address =~ /^[A-Za-z0-9\-\.]+$/)
        {
	    $args{'type'} = 'hostname';
        }
    }
    my $lookup = lookup($address,%args);
    return ( (defined $lookup) and 
	     ( ($lookup eq 'OK') or ($lookup eq 'RELAY') )
	     ) ? 1 : 0;
}

=head2 lookup

 Usage     : lookup ($lookup_key, 
		     'type'=>{'mail','ip','hostname'} ,   [optional]
		     'qualifier'=>'qualifier'             [optional]
		     'file'=>'filename'                   [optional]
		     )
 Purpose   : Do a generic lookup on a $lookup_key in the access.db and
             return the value found (or undef if not)
 Returns   : value in access.db or undef if not found
 Argument  : $lookup_key - mandatory. 'type'=>mail/ip/hostname will cause
             lookups against all necessary lookups according to sendmail logic
             (for things like hostname lookups where subdomains inherit 
             attributes of parent domains, etc.), 'qualifier'=>$q, where $q 
             will be preprended to the beginning of all lookups, (e.g., $q =
             'Spam', lookup would be against 'Spam:lookup_value')
 Throws    : 
 Comments  : If not using 'type', the 'qualifier' field can be mimicked by 
             simply looking for 'Qualifier:lookup'.
 See Also  : 

=cut



sub lookup
{
    my ($address,%args) = @_;
    my @check_list;
    if (defined $args{'type'})
    {
	if ($args{'type'} eq 'mail')
	{
	    @check_list = _expand_email($address);
	}
	elsif ($args{'type'} eq 'hostname')
	{
	    @check_list = _expand_hostname($address);
	}
	elsif ($args{'type'} eq 'ip')
	{
	    @check_list = _expand_ip($address);
	}
    }
    else
    {
	@check_list = ($address);
    }

    push(@check_list, '');

    my %access;

    my $filename = $DB_FILE;
    if (defined $args{'file'})
    {
	$filename = $args{'file'};
    }
    my $db  = tie %access, 'BerkeleyDB::Hash', 
                -Flags => DB_RDONLY,
                -Filename => $filename
             or die "Cannot open file $filename: $! $BerkeleyDB::Error\n";


    foreach my $key (@check_list)
    {	
	my $lookup = $key;

	if (defined $args{'qualifier'})
	{
	    $lookup = "$args{'qualifier'}:$lookup";
	}
	$lookup = lc $lookup;

#	print STDERR "looking up '$lookup'\n";

	if ($access{$lookup})
	{
	    my $local_rc = $access{$lookup};
#	    untie %access;
#	    print STDERR "Returning $local_rc\n";
	    return $local_rc;
	}
    }

#    untie %access;
    return undef;
}
    


sub _expand_ip
{
    my $address = shift;
    my @expanded = ();
    
    if ($address =~ /^(?:\d+\.){3}\d+/)
    {
	push @expanded, $address;
	my $shorter = $address;
	$shorter =~ s/\.\d+$//;
	push @expanded, ($shorter);
	$shorter =~ s/\.\d+$//;
	push @expanded, ($shorter);
	$shorter =~ s/\.\d+$//;
	push @expanded, ($shorter);
    }
    return @expanded;
}

sub _expand_hostname
{
    my $hostname = shift;
    my @expanded = ($hostname);
    while (my ($shorter) = $hostname =~ /^[\w\-]+\.(.*)$/)
    {
	push @expanded, ($shorter) if $shorter;
	$hostname = $shorter;
    }
    return @expanded;
} 

sub _expand_email
{
    my $address = shift;
    my @to_check = ($address);
    if ($address !~ /\@/)
    {
	push @to_check, ("$address\@");
    }
    elsif ($address =~ /^.*\@[A-Za-z0-9.\-]*/)
    {
	my ($left,$right) = $address =~ /^(.*\@)([A-Za-z0-9.\-]*)$/;
	push @to_check, ($left) if (defined $left) and ($left) and ($left ne $address);
	if ( (defined $right) and ($right) )
	{
	    push @to_check, ( _expand_hostname($right) );
	}
    }
    return @to_check;
}


=head1 PRIVATE METHODS

Each private function/method is described here.
These methods and functions are considered private and are intended for
internal use by this module. They are B<not> considered part of the public
interface and are described here for documentation purposes only.

=head2 _expand_ip, _expand_hostname, _expand_address

 Usage     : @expanded = _expand_ip($ip); # For example
 Returns   : Given an ip, hostname, or e-mail address, it will expand
             that into the "appropriate lookups" which sendmail would use
             (e.g., given '192.168.1.2', _expand_ip would return
             192.168.1.2, 192.168.1, 192.168, and 192)
 Argument  : The IP Address, hostname, or e-mail address to expand
 Throws    : 
 Comments  : 
 See Also  : 

=cut


1; #this line is important and will help the module return a true value
__END__


