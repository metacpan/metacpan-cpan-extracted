package Perlwikipedia::Plugin::ImageTester;

use strict;
use warnings;
use WWW::Mechanize;
use HTML::Entities;
use URI::Escape;
use XML::Simple;
use Carp;

our $VERSION = "0.1.2";

=head1 NAME

Perlwikipedia::Plugin::ImageTester - a plugin for Perlwikipedia which contains image copyright checking and analysis for the english wikipedia

=head1 SYNOPSIS

use Perlwikipedia;

my $editor = Perlwikipedia->new('Account');
$editor->login('Account', 'password');
$editor->checkimage('File:Test.jpg');

=head1 DESCRIPTION

Perlwikipedia is a framework that can be used to write Wikipedia bots. Perlwikipedia::Plugin::ImageTester can be used to check and tag images for common copyright issues. It should not be assumed to be perfect, caveat emptor.

=head1 AUTHOR

Dan Collins (ST47) and others

=head1 METHODS

=over 4

=item import()

Calling import from any module will, quite simply, transfer these subroutines into that module's namespace. This is possible from any module which is compatible with Perlwikipedia.pm.

=cut

sub import {
	no strict 'refs';
	foreach my $method (qw/checkimage notag norat nfcc10c nosrc toobig duplicate badusercheck optout ratnotag send_notify nfcc10calbum nfcc10ctryauto/) {
		*{caller() . "::$method"} = \&{$method};
	}
}

=item checkimage($image[, $user[, $tag[, $imagetext[, $imagetextnotemp[, @links]]]]])

This sub performs the actual analysis. All paramaters after $image are optional. Returns:
-1 if the image is free
0 if the image is non-free but appears to be OK
1 if the bot is not able to locate any licensing or a rationale
2 if the bot can confirm that the image is non-free but does not have a rationale
3 if the bot cannot locate any source. This is experimental.
5 if the image appears to lack a link to the article it is used it, failing nfcc#10c
6 if the image does appear to have a rationale, but lacks a license tag

The bot may also return a decimal value. If you do not want to handle these separately, then calling int() on the return value will work. For example, 5.1 indicates an album cover that fails nfcc#10c. If you do not want to handle such things separately, then int() will return 5, which is a generic image that fails nfcc#10c.

=cut

sub checkimage {
        my $self=shift;
	my $image=shift;
	my $user=shift || ($self->get_users($image))[0];
	my $tag=shift || '';
	my $imagetext=shift || $self->get_text($image);
	my $imagetextnotemp=shift || $imagetext;
	my @links=shift;
	$imagetextnotemp=~s/\{\{.+?\}\}//sg;
	unless ($tag) {$imagetext=~/\{(.+?)[\}\|]/; $tag=$1;}
        if ($imagetext=~/\{\{(?:Non-free|fair use|music sample)/i and $imagetextnotemp!~/(\w+\W+){25}/ and $imagetext!~/\{\{Information\W*(\w+\W+){25}/i and $imagetext!~/rationale|\{\{logo fur|\{\{Non-free use|\{\{Non-free media|\{\{Non-free image|\{\{album cover fur|\{\{Non-free fair use rationale|\{\{Historic fur|\{\{User:GeeJo\/FUR|\{\{Film cover fur|\{\{Book cover fur/i and $tag!~/C-uploaded/i) {
                #IF this is a non-free image (indicated by a tag with a name starting with non-free, fair use, or music sample,
                #AND the image text (excluding templates and template parameters, like {{Information}} or the rationale form) has 
                #LESS THAN 25 words,
                #AND the image does not include the word "rationale" or any of the templates logo fur, non-free use,
                #non-free media, non-free image, album cover fur, non-free fair use rationale, historic fur, User:GeeJo/FUR,
                #film cover fur, book cover fur,
                #AND the image was not copied from commons for use on the main page.
                return 2; #Go to sub norat
        } elsif ($tag=~/./ and $imagetextnotemp!~/self|attribution|mine|my|source|from|by|http|Non-free Wikimedia logo|for|photo taken|author/i and $imagetext!~/\{\{(C-uploaded|user|Brands of the World|logo|album)|source\s*=\s*[a-zA-Z\[]/i and $imagetext!~/Author\s*=\s*\[*User/i) {
                return 3; #Go to sub nosrc
#       } elsif ($tag=~/Non-free|fair use|music sample/i and $tag!~/reduce/i and ($dimx*$dimy>=350000)) {
#               return 4; #Go to sub toobig (disabled)
        } elsif ($imagetext=~/\{Non-free|\{fair use|\{music sample/i and $imagetext!~/\[\[((?!(Image|Wikipedia|Portal|Category|WP|CAT|Talk|User)).+?:)?[^:]+\]|article\s*\=\s*[\[\'\.a-z0-9]|\{\{.*?(fur|filmr)\s?\|\s?[\[\.a-z0-9]/i and $imagetext !~/\{wikipedia-screenshot|\{non-free fair use in/i) {
                #This is going to be the controversial one, I reckon. IF:
                #The image is non-free,
                #AND the image does not contain an internal link ([[]]) to anywhere other than these namespaces:
                        #Image, Wikipedia Portal, Category, WP, CAT, Talk, User
                #AND the image does not have an article= parameter followed by a dot, a letter, or a number,
                #AND the image does not use a template ending in "fur" followed immediately by a parameter beginning with a dot,
                        #letter, or number
                @links = $self->links_to_image($image) unless @links;
                my $regex = join('|', @links);
                unless ($imagetext=~/$regex/i) {
                        #AND the image HAS links AND they are not referenced OR the image DOES NOT HAVE links 
			if ($imagetext=~/album/) {
				return 5.1;
			}
                        return 5; #Go to sub nfcc10c
                } else {
                        return 0;
                }
        } elsif ($tag!~/./) {
                #Tag is blank. This means the bot couldn't find any templates when it looked. This could occur for images from 
                #commons if they were run through this subroutine.
	        if ($imagetextnotemp!~/(\w+\W+){25}/ and $imagetext!~/\{\{Information\W*(\w+\W+){25}/i and $imagetext!~/rationale|\{\{logo fur|\{\{Non-free use|\{\{Non-free media|\{\{Non-free image|\{\{album cover fur|\{\{Non-free fair use rationale|\{\{Historic fur|\{\{User:GeeJo\/FUR|\{\{Film cover fur|\{\{Book cover fur/i) {
			return 1; #Go to sub notag - image has no rationale
		} else {
			return 6; #Rationale but no tag
		}
        } elsif ($imagetext=~/\{Non-free|\{fair use|\{music sample/i) {
		return 0;
	}
        return -1; #Go nowhere, note that this is probably a free image
}

=item notag($image[, $user[, $imagetext[, $more]]])

Tags $image for deletion, warns $user. $imagetext is optional but recommended to save you a page load. Not passing $user will result in the user not being warned. $more is a string which will be pasted on the end of the warning, if one is sent.

=cut

sub notag {
	my $self=shift;
	my $image=shift;
	my $user=shift;
	my $imagetext=shift || $self->get_text($image);
	my $more=shift;
        if ($imagetext=~/\{\{di/i) {print "Already tagged\n";return}
        my $usertalk=$user;
       	$usertalk=~s/User:/User talk:/i;
        if ($imagetext=~/self-made|my|mine|\bI\b/i) {
                $self->edit($image, "{{subst:nld}}\n\n" . $imagetext, "This image has no licensing information");
                if ($usertalk=~/User talk:../ and not &optout($user)) {
                        $self->edit($usertalk, $self->get_text($usertalk) . "\n\n{{subst:User:STBotI/nocopyrightclaimself|1=$image}} NOTE: once you correct this, please remove the tag from the image's page. $more~~~~", "$image may be deleted!");
                }
        } else {
                $self->edit($image, "{{subst:nld}}\n\n" . $imagetext, "This image has no licensing information");
                if ($usertalk=~/User talk:../ and not &optout($user)) {
                        $self->edit($usertalk, $self->get_text($usertalk) . "\n\n{{subst:User:STBotI/nocopyright|1=$image}} NOTE: once you correct this, please remove the tag from the image's page. $more~~~~", "$image may be deleted!");
                }
        }
}

=item norat($image[, $user[, $imagetext[, $more]]])

Tags $image for deletion, warns $user. $imagetext is optional but recommended to save you a page load. Not passing $user will result in the user not being warned. $more is a string which will be pasted on the end of the warning, if one is sent.

=cut

sub norat {
	my $self=shift;
	my $image=shift;
	my $user=shift;
	my $imagetext=shift || $self->get_text($image);
	my $more=shift;
        my $usertalk=$user;
        $usertalk=~s/User:/User talk:/i;
        print "$image,$user,$usertalk\n";
        if ($imagetext=~/\{\{di/i) {print "Already tagged\n";return}
        $self->edit($image, "{{subst:nrd}}\n\n" . $imagetext, "This image has no rationale");
        if ($usertalk=~/User talk:../ and not &optout($user)) {
                $self->edit($usertalk, $self->get_text($usertalk) . "\n\n{{subst:User:STBotI/norat|1=$image}} NOTE: once you correct this, please remove the tag from the image's page. $more~~~~", "$image may be deleted!");
        }
}

=item nfcc10c($image[, $user[, $imagetext[, $more]]])

Tags $image for deletion, warns $user. $imagetext is optional but recommended to save you a page load. Not passing $user will result in the user not being warned. $more is a string which will be pasted on the end of the warning, if one is sent.

=cut

sub nfcc10c {
	my $self=shift;
	my $image=shift;
	my $user=shift;
	my $imagetext=shift || $self->get_text($image);
	my $more=shift;
        my $usertalk=$user;
        $usertalk=~s/User:/User talk:/i;
        if ($imagetext=~/\{\{di/i) {print "Already tagged\n";return}
        $self->edit($image, "{{di-disputed fair use rationale|concern=invalid rationale per [[WP:NFCC#10c]]: ''The name of each article in which fair use is claimed for the item, and a separate fair-use rationale for each use of the item, as explained at [[Wikipedia:Non-free use rationale guideline]]. The rationale is presented in clear, plain language, and is relevant to each use''|date={{subst:CURRENTMONTHNAME}} {{subst:CURRENTDAY}} {{subst:CURRENTYEAR}}}}\n\n" . $imagetext, "This image has no valid rationale");
        if ($usertalk=~/User talk:../ and not &optout($user)) {
                $self->edit($usertalk, $self->get_text($usertalk) . "\n\n{{subst:User:STBotI/NFCC10c|1=$image}} NOTE: once you correct this, please remove the tag from the image's page. $more~~~~", "$image may be deleted!");
        }
}

=item nosrc($image[, $user[, $imagetext[, $more]]])

Tags $image for deletion, warns $user. $imagetext is optional but recommended to save you a page load. Not passing $user will result in the user not being warned. $more is a string which will be pasted on the end of the warning, if one is sent.

=cut

sub nosrc {
	my $self=shift;
	my $image=shift;
	my $user=shift;
	my $imagetext=shift || $self->get_text($image);
	my $more=shift;
my $usertalk=$user;
$usertalk=~s/User:/User talk:/i;
if ($imagetext=~/\{\{di/i) {print "Already tagged\n";return}
$self->edit($image, "{{subst:nsd}}\n\n" . $imagetext, "This image has no source");
if ($usertalk=~/User talk:../ and not &optout($user)) {
$self->edit($usertalk, $self->get_text($usertalk) . "\n\n{{subst:User:STBotI/nosourse|1=$image}} NOTE: once you correct this, please remove the tag from the image's page. $more~~~~", "$image may be deleted!");
}
}

=item toobig($image[, $imagetext])

Tags $image for shrinking. $imagetext is optional but recommended to save you a page load.

=cut

sub toobig {
	my $self=shift;
	my $image=shift;
	my $user=shift;
	my $imagetext=shift || $self->get_text($image);
	my $more=shift;
if ($imagetext=~/non-free reduce/i) {return;}
$self->edit($image, "{{non-free reduce}}\n\n" . $imagetext, "This image is too big");
}

=item duplicate($image, $oldimage)

Tags $image as a duplicate of $oldimage, unless it is already tagged.

=cut

sub duplicate {
my ($self, $image, $oldimage)=@_;
my $imagetext=$self->get_text($image);
if ($imagetext=~/\{\{deleted/i) {return}
$self->edit($image, $imagetext . "\n\n{{deletedimage|$oldimage}}", "This image is a duplicate");
}

=item badusercheck()

Don't use this. This shouldn't even be in this module.

=cut

sub badusercheck {
my ($self, $user, $kernel, %badusers)=@_;
$badusers{$user}++;
if ($badusers{$user}/5 == int($badusers{$user}/5)) {
	my $num=$badusers{$user}/5;
	my $warning;
	my $messagea;
	if ($num==1) {$warning="~~~~\n\n{{subst:User:ST47/sbu}} "}
	if ($num==2) {$messagea=" User HAS been warned with blocking"}
	$kernel->post('irc.freenode.net'=>privmsg=>'#wikipedia-en-alerts'=>"!imageabuse [[$user]] has been warned many times for uploading bad images, please check his uploads. (Report number $num)$messagea");
	return ("Additionally, if you continue uploading bad images, you may be [[WP:BLOCK|blocked from uploading]].$warning ", %badusers);
} elsif ($badusers{$user}==3) {
	return ("Additionally, if you continue uploading bad images, you may be [[WP:BLOCK|blocked from uploading]]. ", %badusers);
} else { return ("", %badusers)}
}

=item optout($user)

A simple unified opt out list. Pass a user, returns 1 if they're on the list, returns 0 otherwise. Not really useful since noone actually knows it exists.

=cut

sub optout {
	my ($user)=@_;
	if ($user=~/User:(23skidoo|TreasuryTag)/) {
		return 1;
	} else {
		return 0;
	}
}

=item ratnotag($image[, $user[, $imagetext[, $more]]])

Tags $image for deletion, warns $user. $imagetext is optional but recommended to save you a page load. Not passing $user will result in the user not being warned. $more is a string which will be pasted on the end of the warning, if one is sent.

=cut

sub ratnotag {
	my $self=shift;
	my $image=shift;
	my $user=shift;
	my $imagetext=shift || $self->get_text($image);
	my $more=shift;
        my $usertalk=$user;
        $usertalk=~s/User:/User talk:/i;
        if ($imagetext=~/\{\{di/i) {print "Already tagged\n";return}
        $self->edit($image, "{{subst:User:ST47/rnt}}\n\n" . $imagetext, "This image has no licensing information");
        if ($usertalk=~/User talk:../ and not &optout($user)) {
               $self->edit($usertalk, $self->get_text($usertalk) . "\n\n{{subst:User:STBotI/nocopyrightclaimself|1=$image}} NOTE: once you correct this, please remove the tag from the image's page. $more~~~~", "$image may be deleted!");
        }
}

=item send_notify($image[, $operator])

Gets a list of pages $image is used on in the mainspace and leaves a generic message on each talk page. Include $operator for the username to be displayed in the message.

=cut

sub send_notify {
	my $self=shift;
	my $image=shift;
	my $operator=shift || 'this bot\'s operator';
	my @pages=$self->links_to_image($image);
	print scalar(@pages)." pages link to $image\n";
	foreach my $page (@pages) {
		my $talk=$page;
		if ($page=~/:/) {next}
		$talk="Talk:$talk";
		my $text=$self->get_text($talk);
		if ($text=~/STBotI|--bot warning $image--/) {next}
		$self->edit($talk, $text."\n\n".
		"==An image on this page may be deleted==\n".
		"This is an automated message regarding an image used ".
		"on this page. The image [[:$image]], found on ".
		"[[:$page]], has been nominated for deletion because ".
		"it does not meet Wikipedia image policy. Please see ".
		"the image description page for more details. If this ".
		"message was sent in error (that is, the image is not ".
		"up for deletion, or was left on the wrong talk ".
		"page), please contact $operator. <!--bot warning $image--> ~~~~",
		"$image may be deleted!");
	}
}

=item nfcc10calbum($image[, $user[, $imagetext[, $more]]])

Attempts to add a link to the article that $image is used on. If it fails, tags $image for deletion, warns $user. $imagetext is optional but recommended to save you a page load. Not passing $user will result in the user not being warned. $more is a string which will be pasted on the end of the warning, if one is sent. If an autoresolution is attempted, returns the autores code (true so you can retest the image). Otherwise, calls the traditional tagging routine and returns 0.

=cut

sub nfcc10calbum {
	my $self=shift;
	my $image=shift;
	my $user=shift;
	my $imagetext=shift || $self->get_text($image);
	my $more=shift;
        my $usertalk=$user;
	my $article=($self->links_to_image($image))[0];
	unless ($article) {
		print "Autoresolution failed, no article.\n";
		$self->nfcc10c($image,$user,$imagetext,$more);
	}
	if ($imagetext=~s/==\s?(Fair use rationale for).+?==/== $1 [[$article]] ==/i) {
		print "Resolution successful, attempting to save modified text. Rule 5.1 autores 1\n";
		$self->edit($image, $imagetext, "Attempting autoresolution of NFCC10C album cover issues. Rule 5.1, Autoresolution 1.");
		return 1;
	} else {
		print "Autoresolution failed, no change.\n";
		$self->nfcc10c($image,$user,$imagetext,$more);
	}
	return 0;
#	if ($retval==5) {$self->nfcc10c($image,$user,$imagetext,$more)}
}


=item nfcc10ctryauto($image[, $user[, $imagetext[, $more]]])

Attempts to add a link to the article that $image is used on. If it fails, tags $image for deletion, warns $user. $imagetext is optional but recommended to save you a page load. Not passing $user will result in the user not being warned. $more is a string which will be pasted on the end of the warning, if one is sent. If an autoresolution is attempted, returns the autores code (true so you can retest the image). Otherwise, calls the traditional tagging routine and returns 0.

=cut

sub nfcc10ctryauto {
	my $self=shift;
	my $image=shift;
	my $user=shift;
	my $imagetext=shift || $self->get_text($image);
	my $more=shift;
        my $usertalk=$user;
	my $article=($self->links_to_image($image))[0];
	unless ($article) {
		print "Autoresolution failed, no article.\n";
		$self->nfcc10c($image,$user,$imagetext,$more);
	}
	if ($imagetext=~s/==\s?(Fair use rationale).+?==/== $1 for [[$article]] ==/i) {
		print "Resolution successful, attempting to save modified text. Rule 5 autores 1\n";
		$self->edit($image, $imagetext, "Attempting autoresolution of NFCC10C album cover issues. Rule 5, Autoresolution 1.");
		return 1;
	} else {
		print "Autoresolution failed, no change.\n";
		$self->nfcc10c($image,$user,$imagetext,$more);
	}
	return 0;
#	if ($retval==5) {$self->nfcc10c($image,$user,$imagetext,$more)}
}

1;
