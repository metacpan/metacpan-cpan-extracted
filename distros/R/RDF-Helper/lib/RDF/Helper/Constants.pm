package RDF::Helper::Constants;
use strict;
use warnings;
use vars qw(%EXPORT_TAGS @ISA @EXPORT_OK);
use Exporter;

@ISA = qw (Exporter);

my @FOAF_EXPR = qw(FOAF_HOMEPAGE FOAF_NAME FOAF_PASTPROJECT FOAF_TIPJAR 
                FOAF_GIVENNAME FOAF_KNOWS FOAF_THUMBNAIL FOAF_PLAN
                FOAF_PRIMARYTOPIC FOAF_MYERSBRIGGS FOAF_TITLE
                FOAF_AIMCHATID FOAF_JABBERID FOAF_MADE FOAF_INTEREST 
                FOAF_NICK FOAF_IMG FOAF_PERSON FOAF_CURRENTPROJECT
                FOAF_TOPIC FOAF_WORKPLACEHOMEPAGE FOAF_LOGO FOAF_MBOX_SHA1SUM 
                FOAF_FIRSTNAME FOAF_GENDER FOAF_WEBLOG FOAF_MSNCHATID 
                FOAF_IMAGE FOAF_GEEKCODE FOAF_FAMILY_NAME FOAF_WORKINFOHOMEPAGE 
                FOAF_SCHOOLHOMEPAGE FOAF_DEPICTION FOAF_PHONE 
                FOAF_TOPIC_INTEREST FOAF_DEPICTS FOAF_MBOX FOAF_YAHOOCHATID 
                FOAF_MAKER FOAF_PAGE FOAF_PERSONALPROFILEDOCUMENT 
                FOAF_SURNAME FOAF_DOCUMENT FOAF_ICQCHATID FOAF_GROUP
                FOAF_MEMBER FOAF_NS); 

my @RSS1_EXPR  = qw(RSS1_NS RSS1_DESCRIPTION RSS1_TITLE RSS1_CHANNEL 
                 RSS1_LINK RSS1_IMAGE RSS1_ITEMS RSS1_ITEM RSS1_NAME
                 RSS1_URL RSS1_TEXTINPUT);

my @DC_EXPR = qw(DC_NS DC_TITLE DC_CREATOR DC_SUBJECT DC_DESCRIPTION
              DC_PUBLISHER DC_CONTRIBUTOR DC_DATE DC_TYPE DC_FORMAT
              DC_IDENTIFIER DC_SOURCE DC_LANGUAGE DC_RELATION
              DC_COVERAGE DC_RIGHTS);

my @COMMENT_EXPR = qw(COMMENT_NS COMMENT_COMMENTS COMMENT_COMMENT
                      COMMENT_NAME COMMENT_EMAIL COMMENT_IP
                      COMMENT_URL COMMENT_DATE COMMENT_BODY);

my @DCTERMS_EXPR = qw(DCTERMS_NS DCTERMS_ALTERNATIVE DCTERMS_ABSTRACT
                      DCTERMS_TABLEOFCONTENTS DCTERMS_CREATED 
                      DCTERMS_VALID DCTERMS_AVAILABLE DCTERMS_ISSUED
                      DCTERMS_MODIFIED DCTERMS_DATEACCEPTED
                      DCTERMS_DATECOPYRIGHTED DCTERMS_DATESUBMITTED
                      DCTERMS_EXTENT DCTERMS_MEDIUM DCTERMS_ISVERSIONOF
                      DCTERMS_HASVERSION DCTERMS_ISREPLACEDBY
                      DCTERMS_REPLACES DCTERMS_ISREQUIREDBY 
                      DCTERMS_REQUIRES DCTERMS_ISPARTOF DCTERMS_HASPART
                      DCTERMS_ISREFERENCEDBY DCTERMS_REFERENCES
                      DCTERMS_ISFORMATOF DCTERMS_HASFORMAT 
                      DCTERMS_CONFORMSTO DCTERMS_SPATIAL
                      DCTERMS_TEMPORAL DCTERMS_AUDIENCE DCTERMS_MEDIATOR);

my @RELATIONSHIP_EXPR = qw(REL_NS REL_FRIENDOF REL_ACQUAINTANCEOF REL_PARENTOF
                           REL_SIBLINGOF REL_CHILDOF REL_GRANDCHILDOF
                           REL_SPOUSEOF REL_ENEMYOF REL_ANTAGONISTOF 
                           REL_AMBIVALENTOF REL_LOSTCONTACTWITH REL_KNOWSOF
                           REL_WOULDLIKETOKNOW REL_KNOWSINPASSING 
                           REL_KNOWSBYREPUTATION REL_CLOSEFRIENDOF REL_HASMET
                           REL_WORKSWITH REL_COLLEAGUEOF REL_COLLABORATESWITH
                           REL_EMPLOYEROF REL_EMPLOYEDBY REL_MENTOROF REL_APPRENTICETO
                           REL_LIVESWITH REL_NEIGHBOROF REL_GRANDPARENTOF 
                           REL_LIFEPARTNEROF REL_ENGAGEDTO REL_ANCESTOROF 
                           REL_DESCENDANTOF REL_PARTICIPANTIN REL_PARTICIPANT);

my @XML_EXP = qw (XML_NS XMLA_LANG XMLA_BASE);

my @RDF_EXP = qw (RDF_NS RDF_RDF RDF_DESCRIPTION RDF_BAG RDF_ALT RDF_SEQ
                  RDF_LI RDF_TYPE RDF_OBJECT RDF_SUBJECT RDF_PREDICATE
                  RDF_STATEMENT RDF_PROPERTY RDF_LIST RDF_FIRST RDF_REST 
                  RDF_NIL RDFA_ABOUT RDFA_ABOUTEACH RDFA_ID RDFA_NODEID 
                  RDFA_BAGID RDFA_RESOURCE RDFA_PARSETYPE RDFA_TYPE 
                  RDFA_DATATYPE RDF_XMLLITERAL);


my @RDFS_EXP = qw(RDFS_NS RDFS_RESOURCE RDFS_CLASS RDFS_LITERAL
                  RDFS_CONTAINER RDFS_CONTAINER_MEMBER
                  RDFS_IS_DEFINED_BY RDFS_MEMBER RDFS_SUBCLASS_OF
                  RDFS_SUBPROPERTY_OF RDFS_COMMENT RDFS_LABEL
                  RDFS_DOMAIN RDFS_RANGE RDFS_SEE_ALSO);

my @ALL = (@FOAF_EXPR, @RSS1_EXPR, @DC_EXPR, @DCTERMS_EXPR, @COMMENT_EXPR, @RELATIONSHIP_EXPR, @XML_EXP, @RDF_EXP, @RDFS_EXP);

%EXPORT_TAGS = (all     => \@ALL,
                foaf    => \@FOAF_EXPR,
                dc      => \@DC_EXPR,
                rss1    => \@RSS1_EXPR,
                dcterms => \@DCTERMS_EXPR,
                comment => \@COMMENT_EXPR,
                relationship => \@RELATIONSHIP_EXPR,
                xml     => \@XML_EXP, 
                rdf     => \@RDF_EXP, 
                rdfs    => \@RDFS_EXP,
                xml     => \@XML_EXP);

@EXPORT_OK = (@ALL, @FOAF_EXPR, @DC_EXPR, @RSS1_EXPR, 
              @COMMENT_EXPR, @RELATIONSHIP_EXPR, @XML_EXP, @RDF_EXP,
              @RDFS_EXP);

# XML
use constant XML_NS  => 'http://www.w3.org/XML/1998/namespace';
use constant XMLA_LANG => XML_NS . 'lang';
use constant XMLA_BASE => XML_NS . 'base';

# RDF
use constant RDF_NS => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
use constant RDF_RDF         => RDF_NS . 'RDF';
use constant RDF_DESCRIPTION => RDF_NS . 'Description';
use constant RDF_BAG         => RDF_NS . 'Bag';
use constant RDF_ALT         => RDF_NS . 'Alt';
use constant RDF_SEQ         => RDF_NS . 'Seq';
use constant RDF_LI          => RDF_NS . 'li';
use constant RDF_TYPE        => RDF_NS . 'type';
use constant RDF_OBJECT      => RDF_NS . 'object';
use constant RDF_SUBJECT     => RDF_NS . 'subject';
use constant RDF_PREDICATE   => RDF_NS . 'predicate';
use constant RDF_STATEMENT   => RDF_NS . 'Statement';
use constant RDF_PROPERTY    => RDF_NS . 'Property';
use constant RDF_LIST        => RDF_NS . 'List';
use constant RDF_FIRST       => RDF_NS . 'first';
use constant RDF_REST        => RDF_NS . 'rest';
use constant RDF_NIL         => RDF_NS . 'nil';
use constant RDF_VALUE       => RDF_NS . 'value';
use constant RDF_XMLLITERAL  => RDF_NS . 'XMLLiteral';

# RDF attributes
use constant RDFA_ABOUT      => RDF_NS . 'about';
use constant RDFA_ABOUTEACH  => RDF_NS . 'aboutEach';
use constant RDFA_ID         => RDF_NS . 'ID';
use constant RDFA_NODEID     => RDF_NS . 'nodeID';
use constant RDFA_BAGID      => RDF_NS . 'bagID';
use constant RDFA_RESOURCE   => RDF_NS . 'resource';
use constant RDFA_PARSETYPE  => RDF_NS . 'parseType';
use constant RDFA_TYPE       => RDF_NS . 'type';
use constant RDFA_DATATYPE   => RDF_NS . 'datatype';

# RDFS
use constant RDFS_NS               => 'http://www.w3.org/2000/01/rdf-schema#';
use constant RDFS_RESOURCE         => RDFS_NS . 'Resource';
use constant RDFS_CLASS            => RDFS_NS . 'Class';
use constant RDFS_LITERAL          => RDFS_NS . 'Literal';
use constant RDFS_CONTAINER        => RDFS_NS . 'Container';
use constant RDFS_CONTAINER_MEMBER => RDFS_NS . 'ContainerMembershipProperty';

use constant RDFS_IS_DEFINED_BY    => RDFS_NS . 'isDefinedBy';
use constant RDFS_MEMBER           => RDFS_NS . 'member';
use constant RDFS_SUBCLASS_OF      => RDFS_NS . 'subClassOf';
use constant RDFS_SUBPROPERTY_OF   => RDFS_NS . 'subPropertyOf';
use constant RDFS_COMMENT          => RDFS_NS . 'comment';
use constant RDFS_LABEL            => RDFS_NS . 'label';
use constant RDFS_DOMAIN           => RDFS_NS . 'domain';
use constant RDFS_RANGE            => RDFS_NS . 'range';
use constant RDFS_SEE_ALSO         => RDFS_NS . 'seeAlso';

# FOAF (Friend of a Friend)
use constant FOAF_NS   => 'http://xmlns.com/foaf/0.1/';
use constant FOAF_HOMEPAGE => FOAF_NS . 'homepage';
use constant FOAF_NAME => FOAF_NS . 'name';
use constant FOAF_PASTPROJECT => FOAF_NS . 'pastProject'; 
use constant FOAF_TIPJAR => FOAF_NS . 'tipjar';
use constant FOAF_GIVENNAME => FOAF_NS . 'givenname'; 
use constant FOAF_KNOWS => FOAF_NS . 'knows';
use constant FOAF_THUMBNAIL => FOAF_NS . 'thumbnail';
use constant FOAF_PLAN => FOAF_NS . 'plan';
use constant FOAF_PRIMARYTOPIC => FOAF_NS . 'primaryTopic'; 
use constant FOAF_MYERSBRIGGS => FOAF_NS . 'myersBriggs'; 
use constant FOAF_TITLE => FOAF_NS . 'title'; 
use constant FOAF_AIMCHATID => FOAF_NS . 'aimChatID'; 
use constant FOAF_JABBERID => FOAF_NS . 'jabberID';
use constant FOAF_MADE => FOAF_NS . 'made';
use constant FOAF_INTEREST => FOAF_NS . 'interest'; 
use constant FOAF_NICK => FOAF_NS . 'nick';
use constant FOAF_IMG => FOAF_NS . 'img';
use constant FOAF_PERSON => FOAF_NS . 'Person'; 
use constant FOAF_CURRENTPROJECT => FOAF_NS . 'currentProject'; 
use constant FOAF_TOPIC => FOAF_NS . 'topic';
use constant FOAF_WORKPLACEHOMEPAGE => FOAF_NS . 'workplaceHomepage'; 
use constant FOAF_LOGO => FOAF_NS . 'logo'; 
use constant FOAF_MBOX_SHA1SUM => FOAF_NS . 'mbox_sha1sum'; 
use constant FOAF_FIRSTNAME => FOAF_NS . 'firstName';
use constant FOAF_GENDER => FOAF_NS . 'gender';
use constant FOAF_WEBLOG => FOAF_NS . 'weblog';
use constant FOAF_MSNCHATID => FOAF_NS . 'msnChatID'; 
use constant FOAF_IMAGE => FOAF_NS . 'Image';
use constant FOAF_GEEKCODE => FOAF_NS . 'geekcode'; 
use constant FOAF_FAMILY_NAME => FOAF_NS . 'family_name'; 
use constant FOAF_WORKINFOHOMEPAGE => FOAF_NS . 'workInfoHomepage'; 
use constant FOAF_SCHOOLHOMEPAGE => FOAF_NS . 'schoolHomepage';
use constant FOAF_DEPICTION => FOAF_NS . 'depiction';
use constant FOAF_PHONE => FOAF_NS . 'phone';
use constant FOAF_TOPIC_INTEREST => FOAF_NS . 'topic_interest'; 
use constant FOAF_DEPICTS => FOAF_NS . 'depicts';
use constant FOAF_MBOX => FOAF_NS . 'mbox'; 
use constant FOAF_YAHOOCHATID => FOAF_NS . 'yahooChatID'; 
use constant FOAF_MAKER => FOAF_NS . 'maker';
use constant FOAF_PAGE => FOAF_NS . 'page';
use constant FOAF_PERSONALPROFILEDOCUMENT => FOAF_NS . 'PersonalProfileDocument ';
use constant FOAF_SURNAME => FOAF_NS . 'surname';
use constant FOAF_DOCUMENT => FOAF_NS . 'Document'; 
use constant FOAF_ICQCHATID => FOAF_NS . 'icqChatID';
# Group stuff
use constant FOAF_GROUP => FOAF_NS . 'Group'; 
use constant FOAF_MEMBER => FOAF_NS . 'member'; 

# Relationship extension for FOAF
use constant REL_NS => 'http://purl.org/vocab/relationship/';
use constant REL_FRIENDOF => REL_NS . 'friendOf';
use constant REL_ACQUAINTANCEOF => REL_NS . 'acquaintanceOf';
use constant REL_PARENTOF => REL_NS . 'parentOf';
use constant REL_SIBLINGOF => REL_NS . 'siblingOf';
use constant REL_CHILDOF => REL_NS . 'childOf';
use constant REL_GRANDCHILDOF => REL_NS . 'grandchildOf';
use constant REL_SPOUSEOF => REL_NS . 'spouseOf';
use constant REL_ENEMYOF => REL_NS . 'enemyOf';
use constant REL_ANTAGONISTOF => REL_NS . 'antagonistOf';
use constant REL_AMBIVALENTOF => REL_NS . 'ambivalentOf';
use constant REL_LOSTCONTACTWITH => REL_NS . 'lostContactWith';
use constant REL_KNOWSOF => REL_NS . 'knowsOf';
use constant REL_WOULDLIKETOKNOW => REL_NS . 'wouldLikeToKnow';
use constant REL_KNOWSINPASSING => REL_NS . 'knowsInPassing';
use constant REL_KNOWSBYREPUTATION => REL_NS . 'knowsByReputation';
use constant REL_CLOSEFRIENDOF => REL_NS . 'closeFriendOf';
use constant REL_HASMET => REL_NS . 'hasMet';
use constant REL_WORKSWITH => REL_NS . 'worksWith';
use constant REL_COLLEAGUEOF => REL_NS . 'colleagueOf';
use constant REL_COLLABORATESWITH => REL_NS . 'collaboratesWith';
use constant REL_EMPLOYEROF => REL_NS . 'employerOf';
use constant REL_EMPLOYEDBY => REL_NS . 'employedBy';
use constant REL_MENTOROF => REL_NS . 'mentorOf';
use constant REL_APPRENTICETO => REL_NS . 'apprenticeTo';
use constant REL_LIVESWITH => REL_NS . 'livesWith'; 
use constant REL_NEIGHBOROF => REL_NS . 'neighborOf';
use constant REL_GRANDPARENTOF => REL_NS . 'grandparentOf';
use constant REL_LIFEPARTNEROF => REL_NS . 'lifePartnerOf';
use constant REL_ENGAGEDTO => REL_NS . 'engagedTo';
use constant REL_ANCESTOROF => REL_NS . 'ancestorOf';
use constant REL_DESCENDANTOF => REL_NS . 'descendantOf';
use constant REL_PARTICIPANTIN => REL_NS . 'participantIn';
use constant REL_PARTICIPANT => REL_NS . 'participant';

# RSS 1.0
use constant RSS1_NS          => 'http://purl.org/rss/1.0/';
use constant RSS1_DESCRIPTION => RSS1_NS . 'description';
use constant RSS1_TITLE       => RSS1_NS . 'title';
use constant RSS1_CHANNEL     => RSS1_NS . 'channel';
use constant RSS1_LINK        => RSS1_NS . 'link';
use constant RSS1_IMAGE       => RSS1_NS . 'image';
use constant RSS1_ITEMS       => RSS1_NS . 'items';
use constant RSS1_ITEM        => RSS1_NS . 'item';
use constant RSS1_NAME        => RSS1_NS . 'name';
use constant RSS1_URL         => RSS1_NS . 'url';
use constant RSS1_TEXTINPUT   => RSS1_NS . 'textinput';

# Dublin Core
use constant DC_NS          => 'http://purl.org/dc/elements/1.1/';
use constant DC_TITLE       => DC_NS . 'title';
use constant DC_CREATOR     => DC_NS . 'creator';
use constant DC_SUBJECT     => DC_NS . 'subject';
use constant DC_DESCRIPTION => DC_NS . 'description';
use constant DC_PUBLISHER   => DC_NS . 'publisher';
use constant DC_CONTRIBUTOR => DC_NS . 'contributor';
use constant DC_DATE        => DC_NS . 'date';
use constant DC_TYPE        => DC_NS . 'type';
use constant DC_FORMAT      => DC_NS . 'format';
use constant DC_IDENTIFIER  => DC_NS . 'identifier';
use constant DC_SOURCE      => DC_NS . 'source';
use constant DC_LANGUAGE    => DC_NS . 'language';
use constant DC_RELATION    => DC_NS . 'relation';
use constant DC_COVERAGE    => DC_NS . 'coverage';
use constant DC_RIGHTS      => DC_NS . 'rights';

# Dublin Core Terms
use constant DCTERMS_NS              => 'http://purl.org/dc/terms/';
use constant DCTERMS_ALTERNATIVE     => DCTERMS_NS . 'alternative';
use constant DCTERMS_ABSTRACT        => DCTERMS_NS . 'abstract';
use constant DCTERMS_TABLEOFCONTENTS => DCTERMS_NS . 'tableOfContents';
use constant DCTERMS_CREATED         => DCTERMS_NS . 'created'; 
use constant DCTERMS_VALID           => DCTERMS_NS . 'valid';
use constant DCTERMS_AVAILABLE       => DCTERMS_NS . 'available';
use constant DCTERMS_ISSUED          => DCTERMS_NS . 'issued'; 
use constant DCTERMS_MODIFIED        => DCTERMS_NS . 'modified'; 
use constant DCTERMS_DATEACCEPTED    => DCTERMS_NS . 'dateAccepted'; 
use constant DCTERMS_DATECOPYRIGHTED => DCTERMS_NS . 'dateCopyrighted'; 
use constant DCTERMS_DATESUBMITTED   => DCTERMS_NS . 'dateSubmitted'; 
use constant DCTERMS_EXTENT          => DCTERMS_NS . 'extent';
use constant DCTERMS_MEDIUM          => DCTERMS_NS . 'medium';
use constant DCTERMS_ISVERSIONOF     => DCTERMS_NS . 'isVersionOf'; 
use constant DCTERMS_HASVERSION      => DCTERMS_NS . 'hasVersion'; 
use constant DCTERMS_ISREPLACEDBY    => DCTERMS_NS . 'isReplacedBy'; 
use constant DCTERMS_REPLACES        => DCTERMS_NS . 'replaces'; 
use constant DCTERMS_ISREQUIREDBY    => DCTERMS_NS . 'isRequiredBy'; 
use constant DCTERMS_REQUIRES        => DCTERMS_NS . 'requires'; 
use constant DCTERMS_ISPARTOF        => DCTERMS_NS . 'isPartOf'; 
use constant DCTERMS_HASPART         => DCTERMS_NS . 'hasPart'; 
use constant DCTERMS_ISREFERENCEDBY  => DCTERMS_NS . 'isReferencedBy'; 
use constant DCTERMS_REFERENCES      => DCTERMS_NS . 'references'; 
use constant DCTERMS_ISFORMATOF      => DCTERMS_NS . 'isFormatOf'; 
use constant DCTERMS_HASFORMAT       => DCTERMS_NS . 'hasFormat'; 
use constant DCTERMS_CONFORMSTO      => DCTERMS_NS . 'conformsTo'; 
use constant DCTERMS_SPATIAL         => DCTERMS_NS . 'spatial';
use constant DCTERMS_TEMPORAL        => DCTERMS_NS . 'temporal';
use constant DCTERMS_AUDIENCE        => DCTERMS_NS . 'audience';
use constant DCTERMS_MEDIATOR        => DCTERMS_NS . 'mediator';


#

# RSS Comments Extention
use constant COMMENT_NS => 'http://purl.org/net/rssmodules/blogcomments/';
use constant COMMENT_COMMENTS => COMMENT_NS . 'comments';
use constant COMMENT_COMMENT  => COMMENT_NS . 'comment';
use constant COMMENT_NAME     => COMMENT_NS . 'name';
use constant COMMENT_EMAIL    => COMMENT_NS . 'email';
use constant COMMENT_IP       => COMMENT_NS . 'ip';
use constant COMMENT_URL      => COMMENT_NS . 'url';
use constant COMMENT_DATE     => COMMENT_NS . 'date';
use constant COMMENT_BODY     => COMMENT_NS . 'body';

# RSS Syndication Module
use constant SYN_NS    => 'http://purl.org/rss/1.0/modules/syndication/';
use constant SYN_UPDATEPERIOD    => SYN_NS . 'updatePeriod';
use constant SYN_UPDATEFREQUENCY => SYN_NS . 'updateFrequency';
use constant SYN_UPDATEBASE      => SYN_NS . 'updateBase';

1;
