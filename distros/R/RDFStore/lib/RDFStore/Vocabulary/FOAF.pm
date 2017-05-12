# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *

package RDFStore::Vocabulary::FOAF;
{
use vars qw ( $VERSION $Person $Agent $Document $Organization $Project $Group $Image $PersonalProfileDocument $OnlineAccount $OnlineGamingAccount $OnlineEcommerceAccount $OnlineChatAccount $mbox $mbox_sha1sum $gender $geekcode $dnaChecksum $sha1 $based_near $title $nick $jabberID $aimChatID $icqChatID $yahooChatID $msnChatID $name $firstName $givenname $surname $family_name $phone $homepage $page $weblog $tipjar $plan $made $maker $img $depiction $depicts $thumbnail $myersBriggs $workplaceHomepage $workInfoHomepage $schoolHomepage $knows $interest $topic_interest $publications $currentProject $pastProject $fundedBy $logo $topic $primaryTopic $theme $holdsAccount $accountServiceHomepage $accountName $member $membershipClass );
$VERSION='0.41';
use strict;
use RDFStore::Model;
use Carp;

# 
# This package provides convenient access to schema information.
# DO NOT MODIFY THIS FILE.
# It was generated automatically by RDFStore::Vocabulary::Generator
#

# Namespace URI of this schema
$RDFStore::Vocabulary::FOAF::_Namespace= "http://xmlns.com/foaf/0.1/";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::FOAF::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	# A person.
	$RDFStore::Vocabulary::FOAF::Person = createResource($_[0], "Person");
	# An agent (eg. person, group, software or physical artifact).
	$RDFStore::Vocabulary::FOAF::Agent = createResource($_[0], "Agent");
	# A document.
	$RDFStore::Vocabulary::FOAF::Document = createResource($_[0], "Document");
	# An organization.
	$RDFStore::Vocabulary::FOAF::Organization = createResource($_[0], "Organization");
	# A project (a collective endeavour of some kind).
	$RDFStore::Vocabulary::FOAF::Project = createResource($_[0], "Project");
	# A class of Agents.
	$RDFStore::Vocabulary::FOAF::Group = createResource($_[0], "Group");
	# An image.
	$RDFStore::Vocabulary::FOAF::Image = createResource($_[0], "Image");
	# A personal profile RDF document.
	$RDFStore::Vocabulary::FOAF::PersonalProfileDocument = createResource($_[0], "PersonalProfileDocument");
	# An online account.
	$RDFStore::Vocabulary::FOAF::OnlineAccount = createResource($_[0], "OnlineAccount");
	# An online gaming account.
	$RDFStore::Vocabulary::FOAF::OnlineGamingAccount = createResource($_[0], "OnlineGamingAccount");
	# An online e-commerce account.
	$RDFStore::Vocabulary::FOAF::OnlineEcommerceAccount = createResource($_[0], "OnlineEcommerceAccount");
	# An online chat account.
	$RDFStore::Vocabulary::FOAF::OnlineChatAccount = createResource($_[0], "OnlineChatAccount");
	# A personal mailbox, ie. an Internet mailbox associated with exactly one owner, the first owner of this mailbox. This is a 'static inverse functional property', in that  there is (across time and change) at most one individual that ever has any particular value for foaf:mbox.
	$RDFStore::Vocabulary::FOAF::mbox = createResource($_[0], "mbox");
	# The sha1sum of the URI of an Internet mailbox associated with exactly one owner, the  first owner of the mailbox.
	$RDFStore::Vocabulary::FOAF::mbox_sha1sum = createResource($_[0], "mbox_sha1sum");
	# The gender of this Agent (typically but not necessarily 'male' or 'female').
	$RDFStore::Vocabulary::FOAF::gender = createResource($_[0], "gender");
	# A textual geekcode for this person, see http://www.geekcode.com/geek.html
	$RDFStore::Vocabulary::FOAF::geekcode = createResource($_[0], "geekcode");
	# A checksum for the DNA of some thing. Joke.
	$RDFStore::Vocabulary::FOAF::dnaChecksum = createResource($_[0], "dnaChecksum");
	# A sha1sum hash, in hex.
	$RDFStore::Vocabulary::FOAF::sha1 = createResource($_[0], "sha1");
	# A location that something is based near, for some broadly human notion of near.
	$RDFStore::Vocabulary::FOAF::based_near = createResource($_[0], "based_near");
	# Title (Mr, Mrs, Ms, Dr. etc)
	$RDFStore::Vocabulary::FOAF::title = createResource($_[0], "title");
	# A short informal nickname characterising an agent (includes login identifiers, IRC and other chat nicknames).
	$RDFStore::Vocabulary::FOAF::nick = createResource($_[0], "nick");
	# A jabber ID for something.
	$RDFStore::Vocabulary::FOAF::jabberID = createResource($_[0], "jabberID");
	# An AIM chat ID
	$RDFStore::Vocabulary::FOAF::aimChatID = createResource($_[0], "aimChatID");
	# An ICQ chat ID
	$RDFStore::Vocabulary::FOAF::icqChatID = createResource($_[0], "icqChatID");
	# A Yahoo chat ID
	$RDFStore::Vocabulary::FOAF::yahooChatID = createResource($_[0], "yahooChatID");
	# An MSN chat ID
	$RDFStore::Vocabulary::FOAF::msnChatID = createResource($_[0], "msnChatID");
	# A name for some thing.
	$RDFStore::Vocabulary::FOAF::name = createResource($_[0], "name");
	# The first name of a person.
	$RDFStore::Vocabulary::FOAF::firstName = createResource($_[0], "firstName");
	# The given name of some person.
	$RDFStore::Vocabulary::FOAF::givenname = createResource($_[0], "givenname");
	# The surname of some person.
	$RDFStore::Vocabulary::FOAF::surname = createResource($_[0], "surname");
	# The family_name of some person.
	$RDFStore::Vocabulary::FOAF::family_name = createResource($_[0], "family_name");
	# A phone,  specified using fully qualified tel: URI scheme (refs: http://www.w3.org/Addressing/schemes.html#tel).
	$RDFStore::Vocabulary::FOAF::phone = createResource($_[0], "phone");
	# A homepage for some thing.
	$RDFStore::Vocabulary::FOAF::homepage = createResource($_[0], "homepage");
	# A page or document about this thing.
	$RDFStore::Vocabulary::FOAF::page = createResource($_[0], "page");
	# A weblog of some thing (whether person, group, company etc.).
	$RDFStore::Vocabulary::FOAF::weblog = createResource($_[0], "weblog");
	# A tipjar document for this agent, describing means for payment and reward.
	$RDFStore::Vocabulary::FOAF::tipjar = createResource($_[0], "tipjar");
	# A .plan comment, in the tradition of finger and '.plan' files.
	$RDFStore::Vocabulary::FOAF::plan = createResource($_[0], "plan");
	# Something that was made by this agent.
	$RDFStore::Vocabulary::FOAF::made = createResource($_[0], "made");
	# An agent that made this thing.
	$RDFStore::Vocabulary::FOAF::maker = createResource($_[0], "maker");
	# An image that can be used to represent some thing (ie. those depictions which are particularly representative of something, eg. one's photo on a homepage).
	$RDFStore::Vocabulary::FOAF::img = createResource($_[0], "img");
	# A depiction of some thing.
	$RDFStore::Vocabulary::FOAF::depiction = createResource($_[0], "depiction");
	# A thing depicted in this representation.
	$RDFStore::Vocabulary::FOAF::depicts = createResource($_[0], "depicts");
	# A derived thumbnail image.
	$RDFStore::Vocabulary::FOAF::thumbnail = createResource($_[0], "thumbnail");
	# A Myers Briggs (MBTI) personality classification.
	$RDFStore::Vocabulary::FOAF::myersBriggs = createResource($_[0], "myersBriggs");
	# A workplace homepage of some person; the homepage of an organization they work for.
	$RDFStore::Vocabulary::FOAF::workplaceHomepage = createResource($_[0], "workplaceHomepage");
	# A work info homepage of some person; a page about their work for some organization.
	$RDFStore::Vocabulary::FOAF::workInfoHomepage = createResource($_[0], "workInfoHomepage");
	# A homepage of a school attended by the person.
	$RDFStore::Vocabulary::FOAF::schoolHomepage = createResource($_[0], "schoolHomepage");
	# A person known by this person (indicating some level of reciprocated interaction between the parties).
	$RDFStore::Vocabulary::FOAF::knows = createResource($_[0], "knows");
	# A page about a topic of interest to this person.
	$RDFStore::Vocabulary::FOAF::interest = createResource($_[0], "interest");
	# A thing of interest to this person.
	$RDFStore::Vocabulary::FOAF::topic_interest = createResource($_[0], "topic_interest");
	# A link to the publications of this person.
	$RDFStore::Vocabulary::FOAF::publications = createResource($_[0], "publications");
	# A current project this person works on.
	$RDFStore::Vocabulary::FOAF::currentProject = createResource($_[0], "currentProject");
	# A project this person has previously worked on.
	$RDFStore::Vocabulary::FOAF::pastProject = createResource($_[0], "pastProject");
	# An organization funding a project or person.
	$RDFStore::Vocabulary::FOAF::fundedBy = createResource($_[0], "fundedBy");
	# A logo representing some thing.
	$RDFStore::Vocabulary::FOAF::logo = createResource($_[0], "logo");
	# A topic of some page or document.
	$RDFStore::Vocabulary::FOAF::topic = createResource($_[0], "topic");
	# The primary topic of some page or document.
	$RDFStore::Vocabulary::FOAF::primaryTopic = createResource($_[0], "primaryTopic");
	# A theme.
	$RDFStore::Vocabulary::FOAF::theme = createResource($_[0], "theme");
	# Indicates an account held by this agent.
	$RDFStore::Vocabulary::FOAF::holdsAccount = createResource($_[0], "holdsAccount");
	# Indicates a homepage of the service provide for this online account.
	$RDFStore::Vocabulary::FOAF::accountServiceHomepage = createResource($_[0], "accountServiceHomepage");
	# Indicates the name (identifier) associated with this online account.
	$RDFStore::Vocabulary::FOAF::accountName = createResource($_[0], "accountName");
	# Indicates a member of a Group
	$RDFStore::Vocabulary::FOAF::member = createResource($_[0], "member");
	# Indicates the class of individuals that are a member of a Group
	$RDFStore::Vocabulary::FOAF::membershipClass = createResource($_[0], "membershipClass");
};
sub END {
	$RDFStore::Vocabulary::FOAF::Person = undef;
	$RDFStore::Vocabulary::FOAF::Agent = undef;
	$RDFStore::Vocabulary::FOAF::Document = undef;
	$RDFStore::Vocabulary::FOAF::Organization = undef;
	$RDFStore::Vocabulary::FOAF::Project = undef;
	$RDFStore::Vocabulary::FOAF::Group = undef;
	$RDFStore::Vocabulary::FOAF::Image = undef;
	$RDFStore::Vocabulary::FOAF::PersonalProfileDocument = undef;
	$RDFStore::Vocabulary::FOAF::OnlineAccount = undef;
	$RDFStore::Vocabulary::FOAF::OnlineGamingAccount = undef;
	$RDFStore::Vocabulary::FOAF::OnlineEcommerceAccount = undef;
	$RDFStore::Vocabulary::FOAF::OnlineChatAccount = undef;
	$RDFStore::Vocabulary::FOAF::mbox = undef;
	$RDFStore::Vocabulary::FOAF::mbox_sha1sum = undef;
	$RDFStore::Vocabulary::FOAF::gender = undef;
	$RDFStore::Vocabulary::FOAF::geekcode = undef;
	$RDFStore::Vocabulary::FOAF::dnaChecksum = undef;
	$RDFStore::Vocabulary::FOAF::sha1 = undef;
	$RDFStore::Vocabulary::FOAF::based_near = undef;
	$RDFStore::Vocabulary::FOAF::title = undef;
	$RDFStore::Vocabulary::FOAF::nick = undef;
	$RDFStore::Vocabulary::FOAF::jabberID = undef;
	$RDFStore::Vocabulary::FOAF::aimChatID = undef;
	$RDFStore::Vocabulary::FOAF::icqChatID = undef;
	$RDFStore::Vocabulary::FOAF::yahooChatID = undef;
	$RDFStore::Vocabulary::FOAF::msnChatID = undef;
	$RDFStore::Vocabulary::FOAF::name = undef;
	$RDFStore::Vocabulary::FOAF::firstName = undef;
	$RDFStore::Vocabulary::FOAF::givenname = undef;
	$RDFStore::Vocabulary::FOAF::surname = undef;
	$RDFStore::Vocabulary::FOAF::family_name = undef;
	$RDFStore::Vocabulary::FOAF::phone = undef;
	$RDFStore::Vocabulary::FOAF::homepage = undef;
	$RDFStore::Vocabulary::FOAF::page = undef;
	$RDFStore::Vocabulary::FOAF::weblog = undef;
	$RDFStore::Vocabulary::FOAF::tipjar = undef;
	$RDFStore::Vocabulary::FOAF::plan = undef;
	$RDFStore::Vocabulary::FOAF::made = undef;
	$RDFStore::Vocabulary::FOAF::maker = undef;
	$RDFStore::Vocabulary::FOAF::img = undef;
	$RDFStore::Vocabulary::FOAF::depiction = undef;
	$RDFStore::Vocabulary::FOAF::depicts = undef;
	$RDFStore::Vocabulary::FOAF::thumbnail = undef;
	$RDFStore::Vocabulary::FOAF::myersBriggs = undef;
	$RDFStore::Vocabulary::FOAF::workplaceHomepage = undef;
	$RDFStore::Vocabulary::FOAF::workInfoHomepage = undef;
	$RDFStore::Vocabulary::FOAF::schoolHomepage = undef;
	$RDFStore::Vocabulary::FOAF::knows = undef;
	$RDFStore::Vocabulary::FOAF::interest = undef;
	$RDFStore::Vocabulary::FOAF::topic_interest = undef;
	$RDFStore::Vocabulary::FOAF::publications = undef;
	$RDFStore::Vocabulary::FOAF::currentProject = undef;
	$RDFStore::Vocabulary::FOAF::pastProject = undef;
	$RDFStore::Vocabulary::FOAF::fundedBy = undef;
	$RDFStore::Vocabulary::FOAF::logo = undef;
	$RDFStore::Vocabulary::FOAF::topic = undef;
	$RDFStore::Vocabulary::FOAF::primaryTopic = undef;
	$RDFStore::Vocabulary::FOAF::theme = undef;
	$RDFStore::Vocabulary::FOAF::holdsAccount = undef;
	$RDFStore::Vocabulary::FOAF::accountServiceHomepage = undef;
	$RDFStore::Vocabulary::FOAF::accountName = undef;
	$RDFStore::Vocabulary::FOAF::member = undef;
	$RDFStore::Vocabulary::FOAF::membershipClass = undef;
};
1;
};
