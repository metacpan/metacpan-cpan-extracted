
# an example schema, modeled after Request Tracker.

package RT;

BEGIN {
    use base qw(Exporter);
    our @EXPORT_OK = qw($schema);
}

our $schema
    = {
       sql => {  type_col => "t2_type",
	      },
       classes =>
       [

	RT::Attachment =>
	{ fields =>
	  { # back-refs: Transaction
	   iset => { Children => { class => "RT::Attachment",
				   back => "Parent",
				   aggreg => 1,
				 },
		   },
	   string => { MessageId => { sql => "varchar(160)" },
		       Subject => { sql => "varchar(255)" },
		       Filename => { sql => "varchar(255)" },
		       ContentType => { sql => "varchar(80)" },
		       ContentEncoding => { sql => "varchar(80)" },
		       Content => { sql => "LONGTEXT" },
		       Headers => { sql => "LONGTEXT" },
		     },
	   ref => { Creator => undef, },
	   dmdatetime => [ qw(Created) ],
	  },
	},

	RT::Queue =>
	{ fields =>
	  {
	   string => {
		      Name => { sql => "varchar(200)" },
		      Description => { sql => "varchar(255)" },
		      CorrespondAddress => { sql => "varchar(120)" },
		      CommentAddress => { sql => "varchar(120)" },
		     },
	   int => [ qw(InitialPriority FinalPriority
			   DefaultDueIn Disabled) ],
	   ref => { LastUpdatedBy => undef,
		    Creator => undef,
		  },

	   # FIXME - need an on-demand loader that can load partial
	   # contents of containers, this mapping is awful.

	   # In reality, you would never actually load relationships
	   # like "Tickets", you'd use the relationship to query.

 	   iset => { Scrips => { class => "RT::Scrip",
				 aggreg => 1,
				 back => "Queue",
			       },
		     Tickets => { class => "RT::Ticket",
				  aggreg => 1,
				  back => "Queue",
				},
		     Templates => { class => "RT::Template",
				    aggreg => 1,
				    back => "Queue",
				  },
		   },
	   iarray => {
		      CustomFields => { class => "RT::CustomField",
					aggreg => 1,
					back => "Queue",
				      },
		     },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	RT::Link =>
	{ fields =>
	  { string => { Base => { sql => "varchar(240)" },
			Target => { sql => "varchar(240)" },
			Type => { sql => "varchar(20)" },
		      },
	    int => [ # FIXME - are these links? 
		    qw(LocalTarget LocalBase)
		   ],
	    ref => { LastUpdatedBy => undef, },
	    dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	RT::Principal =>
	{ fields =>
	  { string => { PrincipalType => { sql => "varchar(16)" },
		      },
	    ref => { # to users or groups, depending
		    ObjectId => undef,
		   },
	    iset => { ACLs => { class => "RT::ACL",
				aggreg => 1,
				back => "Principal",
			      },
		    },
	    int => [ qw(Disabled) ],
	  },
	},

	RT::Group =>
	{ fields =>
	  { string => { Name => { sql => "varchar(200)" },
			Description => { sql => "varchar(255)" },
			Domain => { sql => "varchar(64)" },
			Type => { sql => "varchar(64)" },
		      },
	    # FIXME - is this actually a ref?
	    int => [ qw(Instance) ],
	    set => { Members => { class => "RT::User",
				  table => "GroupMembers",
				},
		   },
	  },
	},

	RT::ScripCondition =>
	{ fields =>
	  { string => { Name => { sql => "varchar(200)" },
			Description => { sql => "varchar(255)" },
			ExecModule => { sql => "varchar(60)" },
			Argument => { sql => "varchar(255)" },
			ApplicableTransTypes => { sql => "varchar(60)" },
		      },
	   ref => { LastUpdatedBy => undef,
		    Creator => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	RT::Transaction =>
	{ fields =>
	  {
	    #back-refs: Ticket
	   ref => { EffectiveTicket => undef,
		    Creator => undef,
		  },
	   int => { TimeTaken => undef,
		  },
	   string => {
		      Type => { sql => "varchar(20)" },
		      Field => { sql => "varchar(40)" },
		      OldValue => { sql => "varchar(255)" },
		      NewValue => { sql => "varchar(255)" },
		      Data => { sql => "varchar(255)" },
		     },
	   dmdatetime => [ qw(Created) ],
	   iset => { Attachments => { class => "RT::Attachment",
				      back => "Transaction",
				      aggreg => 1,
				    },
		   },
	  },
	},

	RT::Scrip =>
	{ fields =>
	  {#back-refs: Queue
	   string => {
		      Description => { sql => "varchar(255)" },
		      Stage => { sql => "varchar(32)" },
		      ConditionRules => { sql => "text" },
		      ActionRules  => { sql => "text" },
		      CustomIsApplicableCode => { sql => "text" },
		      CustomPrepareCode => { sql => "text" },
		      CustomCommitCode => { sql => "text" },
		     },
	   ref => { Template => undef,
		    LastUpdatedBy => undef,
		    Creator => undef,
		    ScripCondition => undef,
		    ScripAction => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	RT::ACL =>
	{ fields =>
	  {#back-refs: Principal
	   string => {
		      #"User" "Group", "Owner", "Cc" "AdminCc",
		      # "Requestor", "Requestor" 
		      PrincipalType  => { sql => "varchar(25)" },
		      RightName  => { sql => "varchar(25)" },
		      # FIXME - probably unnecessary
		      ObjectType  => { sql => "varchar(25)" },
		     },
	   ref => { Object => undef,
		    # Principal with a user
		    DelegatedBy => undef,
		    # another ACL
		    DelegatedFrom => undef,
		  },
	  },
	},

	# this table represents a de-normalisation of a tree.  Because
	# trees just aren't normal.
	RT::CachedGroupMember =>
	{ fields =>
	  { 
	   ref => { Group => undef,   # RT::Principal
		    Member => undef,  # RT::Principal
		    Via => undef,     # RT::CachedGroupMember
		    #  RT::Prinicpal
		    # this points to the group that the member is
		    # a member of, for ease of deletes.
		    ImmediateParent => undef,
		  },
	   int => {
		   #if this cached group member is a member of this
		   # group by way of a disabled group or this group is
		   # disabled, this will be set to 1 this allows us to
		   # not find members of disabled subgroups when
		   # listing off group members recursively.  Also,
		   # this allows us to have the ACL system elide
		   # members of disabled groups
		   Disabled => undef,
		  },
	  },
	},

	RT::User =>
	{ fields =>
	  { string => {
		       Name => { sql => "varchar(200)" },
		       Password => { sql => "varchar(40)" },
		       Comments => { sql => "BLOB" },
		       Signature => { sql => "BLOB" },
		       EmailAddress => { sql => "varchar(120)" },
		       FreeformContactInfo => { sql => "BLOB" },
		       Organization => { sql => "varchar(200)" },
		       RealName => { sql => "varchar(120)" },
		       NickName => { sql => "varchar(16)" },
		       Lang => { sql => "varchar(16)" },
		       EmailEncoding => { sql => "varchar(16)" },
		       WebEncoding => { sql => "varchar(16)" },
		       ExternalContactInfoId => { sql => "varchar(100)" },
		       ContactInfoSystem => { sql => "varchar(30)" },
		       ContactInfoSystem => { sql => "varchar(30)" },
		       ExternalAuthId => { sql => "varchar(100)" },
		       AuthSystem => { sql => "varchar(30)" },
		       Gecos => { sql => "varchar(16)" },
		       HomePhone => { sql => "varchar(30)" },
		       WorkPhone => { sql => "varchar(30)" },
		       MobilePhone => { sql => "varchar(30)" },
		       PagerPhone => { sql => "varchar(30)" },
		       Address1 => { sql => "varchar(200)" },
		       Address2 => { sql => "varchar(200)" },
		       City => { sql => "varchar(100)" },
		       State => { sql => "varchar(100)" },
		       Zip => { sql => "varchar(16)" },
		       Country => { sql => "varchar(50)" },
		       Timezone => { sql => "varchar(50)" },
		       PGPKey => { sql => "TEXT" },
		      },
	    ref => { LastUpdatedBy => undef,
		     Creator => undef,
		   },
	    dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	RT::Ticket =>
	{ fields =>
	  { #backrefs: Queue
	   int => [ qw(EffectiveId IssueStatement Resolution
		       InitialPriority FinalPriority Priority
		       TimeEstimated TimeWorked TimeLeft Disabled
		      ) ],
	   string => { Type => { sql => "varchar(16)" },
		       Subject => { sql => "varchar(200)" },
		       Status => { sql => "varchar(10)" },
		     },
	   dmdatetime => [ qw(Told Starts Started Due Resolved) ],
	   ref => {
		   Owner => undef,
		   LastUpdatedBy => undef,
		   Creator => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	# 
	RT::ScripAction =>
	{ fields =>
	  { string => { Name => { sql => "varchar(200)" },
			Description => { sql => "varchar(255)" },
			ExecModule => { sql => "varchar(60)" },
			Argument => { sql => "varchar(255)" },
		     },
	   ref => { LastUpdatedBy => undef,
		    Creator => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	# 
	RT::Template =>
	{ fields =>
	  { #backrefs: Queue
	   string => { Name => { sql => "varchar(200)" },
		       Description => { sql => "varchar(255)" },
		       Type => { sql => "varchar(16)" },
		       Language => { sql => "varchar(16)" },
		       Content => { sql => "BLOB" },
		     },
	   iset => { Translations => { class => "RT::Template",
				       #aggreg => 1,
				       back => "TranslationOf",
				     },
		   },
	   ref => { LastUpdatedBy => undef,
		    Creator => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	# 
	RT::TicketCustomFieldValue =>
	{ fields =>
	  { # backrefs: Ticket
	   string => { Name => { Content => "varchar(255)" } },
	   ref => { CustomField => undef,
		    LastUpdatedBy => undef,
		    Creator => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	# 
	RT::CustomField =>
	{ fields =>
	  { # backrefs: Queue
	   string => { Name => { sql => "varchar(200)" },
		       Description => { sql => "varchar(255)" },
		       Type => { sql => "varchar(200)" },
		       Language => { sql => "varchar(16)" },
		       Content => { sql => "BLOB" },
		     },
	   ref => { LastUpdatedBy => undef,
		    Creator => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	   int => [ qw(Disabled) ],
	   iarray => { Values => { class => "RT::CustomFieldValue",
				   back => "CustomField",
				   aggreg => 1,
				 },
		     },
	  },
	},

	# 
	RT::CustomFieldValue =>
	{ fields =>
	  { # backrefs: CustomField
	   string => { Name => { sql => "varchar(200)" },
		       Description => { sql => "varchar(255)" },
		     },
	   ref => { LastUpdatedBy => undef,
		    Creator => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	# 
	RT::Attribute =>
	{ fields =>
	  {
	   string => { Name => { sql => "varchar(255)" },
		       Description => { sql => "varchar(255)" },
		       Content => { sql => "TEXT" },
		       ContentType => { sql => "varchar(16)" },
		       # FIXME - not necessary?
		       ObjectType => { sql => "varchar(64)" },
		     },
	   ref => { LastUpdatedBy => undef,
		    Creator => undef,
		    Object => undef,
		  },
	   dmdatetime => [ qw(Created LastUpdated) ],
	  },
	},

	RT::Session =>
	{ fields =>
	  {
	   ref => { LoggedInUser => undef,
		  },
	   idbif => { -poof => # there goes another one!
		    },
	   dmdatetime => { LastUpdated => { sql => "TIMESTAMP" } },

	  },
	},
       ],
      };

1;
