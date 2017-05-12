package Net::Gnats::TestData::Gtdata;
require Exporter;
use parent 'Exporter';

@EXPORT_OK = qw(schema1 connect_standard connect_standard_wauth conn_bad user conn);

my $LF = chr 10; # 0x0A
my $CR = chr 13; # 0x0D

my $CR   = "\r";
my $LF   = "\n";
my $CRLF = "\r\n";

sub connect_standard {
  my @d = qw();
  push @d,
    @{ conn() },
    @{ user() },
    @{ schema1() };
  return \@d;
}

sub connect_standard_wauth {
  my @d = qw();
  push @d,
    @{ conn() },
    @{ user() },
    @{ user_wauth()},
    @{ schema1() }
    ;
  return \@d;
}

sub connect_badversion {
  my @d = qw();
  push @d,
    @{ conn() },
    @{ user() },
    @{ schema1() };
  return \@d;
}


sub user {
  return ["351-The current user access level is:\r\n",
          "350 admin\r\n",];
}

sub user_wauth {
  return ["210-Now accessing GNATS database 'default'\r\n",
          "210 User access level set to 'admin'\r\n",];
}

sub conn {
  return ["200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n"];
}

sub conn_bad {
  return ["200 my.gnatsd.com GNATS server 3.1.0 ready.\r\n"];
}


sub list_inputfields_initial_1 {
  return ['301 List follows.' . $CRLF,
          'Number'            . $CRLF,
          'Notify-List' . $CRLF,
          'Category' . $CRLF,
          'Synopsis' . $CRLF,
          'Confidential' . $CRLF,
          'Severity' . $CRLF,
          'Priority' . $CRLF,
          'Responsible' . $CRLF,
          '.' . $CRLF
         ];
}

sub list_inputfields_required_1 {
  return ['301 List follows.' . $CRLF,
          '.'                 . $CRLF
         ];
}

sub list_fieldnames_1 {
  return ['301 List follows.' . $CRLF,
          'Number'            . $CRLF,
          'Notify-List'       . $CRLF,
          'Category'          . $CRLF,
          'Synopsis'          . $CRLF,
          'Confidential'      . $CRLF,
          'Severity'          . $CRLF,
          'Priority'          . $CRLF,
          'Responsible'       . $CRLF,
          'State'             . $CRLF,
          'Class'             . $CRLF,
          'Submitter-Id'      . $CRLF,
          'Arrival-Date'      . $CRLF,
          'Closed-Date'       . $CRLF,
          'Last-Modified'     . $CRLF,
          'Originator'        . $CRLF,
          'Release'           . $CRLF,
          'Organization'      . $CRLF,
          'Environment'       . $CRLF,
          'Description'       . $CRLF,
          'How-To-Repeat'     . $CRLF,
          'Fix'               . $CRLF,
          'Release-Note'      . $CRLF,
          'Audit-Trail'       . $CRLF,
          'Unformatted'       . $CRLF,
          '.'                 . $CRLF
         ];
}

sub list_ftyp_1 {
  return ['350-Number' . $CRLF,
          '350-Text' . $CRLF,
          '350-Enum' . $CRLF,
          '350-Text' . $CRLF,
          '350-Enum' . $CRLF,
          '350-Enum' . $CRLF,
          '350-Enum' . $CRLF,
          '350-Enum' . $CRLF,
          '350-Enum' . $CRLF,
          '350-Enum' . $CRLF,
          '350-Enum' . $CRLF,
          '350-Date' . $CRLF,
          '350-Date' . $CRLF,
          '350-Date' . $CRLF,
          '350-Text' . $CRLF,
          '350-Text' . $CRLF,
          '350-MultiText' . $CRLF,
          '350-MultiText' . $CRLF,
          '350-MultiText' . $CRLF,
          '350-MultiText' . $CRLF,
          '350-MultiText' . $CRLF,
          '350-MultiText' . $CRLF,
          '350-MultiText' . $CRLF,
          '350 MultiText' . $CRLF];
}

sub list_fdsc_1 {
  return [ '350-PR Number' . $CRLF,
           '350-Addresses to notify of significant PR changes' . $CRLF,
           '350-What area does this PR fall into?' . $CRLF,
           '350-One-line summary of the PR' . $CRLF,
           '350-Yes/no flag indicating if the PR contents are confidential' . $CRLF,
           '350-How severe is the PR?' . $CRLF,
           '350-How critical is it that the PR be fixed?' . $CRLF,
           '350-The user responsible for the PR' . $CRLF,
           '350-The current state of the PR' . $CRLF,
           '350-The type of bug' . $CRLF,
           '350-Site-specific identification of the PR author' . $CRLF,
           '350-Arrival date of the PR' . $CRLF,
           '350-Date when the PR was closed' . $CRLF,
           '350-Last modification date of the PR' . $CRLF,
           '350-Name of the PR author' . $CRLF,
           '350-Release number or tag' . $CRLF,
           '350-Organization of PR author' . $CRLF,
           '350-Machine, OS, target, libraries' . $CRLF,
           '350-Precise description of the problem' . $CRLF,
           '350-Code/input/activities to reproduce the problem' . $CRLF,
           '350-How to correct or work around the problem, if known' . $CRLF,
           '350-' . $CRLF,
           '350-Log of specific changes to the PR' . $CRLF,
           '350 Miscellaneous text that was not parsed properly' . $CRLF
];
}

sub list_inputdefault_1 {
  return ['350--1' . $CRLF,
          '350-' . $CRLF,
          '350-pending' . $CRLF,
          '350-' . $CRLF,
          '350-yes' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-open' . $CRLF,
          '350-sw-bug' . $CRLF,
          '350-unknown' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350-\\nUnknown' . $CRLF,
          '350-' . $CRLF,
          '350-' . $CRLF,
          '350',]

}


sub list_fieldflags_1 {
  return [ '350-readonly'   . $CRLF,
           '350-textsearch' . $CRLF,
           '350-textsearch' . $CRLF,
           '350-textsearch' . $CRLF,
           '350-textsearch' . $CRLF,
           '350-textsearch' . $CRLF,
           '350-textsearch' . $CRLF,
           '350-textsearch allowAnyValue requireChangeReason' . $CRLF,
           '350-textsearch requireChangeReason' . $CRLF,
           '350-textsearch' . $CRLF,
           '350-textsearch' . $CRLF,
           '350-readonly'   . $CRLF,
           '350-readonly'   . $CRLF,
           '350-readonly'   . $CRLF,
           '350-textsearch' . $CRLF,
           '350-textsearch' . $CRLF,
           '350-'           . $CRLF,
           '350-'           . $CRLF,
           '350-'           . $CRLF,
           '350-'           . $CRLF,
           '350-'           . $CRLF,
           '350-'           . $CRLF,
           '350-'           . $CRLF,
           '350'            . $CRLF];

}

sub list_fvld_1 {
  return [ # fvld Number
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,
          '301 Valid values follow' . $CRLF,
          'pending' . $CRLF,
           '.'.$CRLF,
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,
          '301 Valid values follow' . $CRLF,
          'yes' . $CRLF,
          'no' . $CRLF,
          '.' . $CRLF,

          '301 Valid values follow' . $CRLF,
          'critical' . $CRLF,
          'serious' . $CRLF,
          'non-critical' . $CRLF,
          '.' . $CRLF,

          '301 Valid values follow' . $CRLF,
          'high' . $CRLF,
          'medium' . $CRLF,
          'low' . $CRLF,
          '.' . $CRLF,

           #fvld Responsible
          '301 Valid values follow' . $CRLF,
          'gnats-admin' . $CRLF,
          '.' . $CRLF,

          # fvld State
          '301 Valid values follow' . $CRLF,
          'open' . $CRLF,
          'analyzed' . $CRLF,
          'suspended' . $CRLF,
          'feedback' . $CRLF,
          'closed' . $CRLF,
          '.' . $CRLF,

           # fvld Class
          '301 Valid values follow' . $CRLF,
          'sw-bug' . $CRLF,
          'doc-bug' . $CRLF,
          'support' . $CRLF,
          'change-request' . $CRLF,
          'mistaken' . $CRLF,
          'duplicate' . $CRLF,
          '.' . $CRLF,

          #fvld Submitter-Id
          '301 Valid values follow' . $CRLF,
          'unknown' . $CRLF,
          'customer1' . $CRLF,
          'customer2' . $CRLF,
          '.' . $CRLF,

           #fvld Arrival-Date
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

           #fvld Closed-Date
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

           #fvld Last-Modified
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld Originator
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld Release
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld Organization
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld Environment
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld Description
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld How-To-Repeat
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld Fix
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld Release-Note
          '301 Valid values follow' . $CRLF,
          '..*' . $CRLF,
          '.' . $CRLF,

          #fvld Audit-Trail
          '301 Valid values follow' . $CRLF,
          '..*'                     . $CRLF,
          '.'                       . $CRLF,

           #fvld Unformatted
          '301 Valid values follow' . $CRLF,
          '..*'                     . $CRLF,
          '.'                       . $CRLF,
         ]

}


sub list_ftyp_single_text {
  return ['350 CODE_INFORMATION' . $CRLF,
          'Text'                 . $CRLF,
          '.'                    . $CRLF,
         ];
}

sub list_fdsc_single {
  return ['350 Description for field1' . $CRLF,
          '.' . $CRLF,];
}

sub list_inputdefault_single {
  return ['350 CODE_INFORMATION' . $CRLF,
          'default' . $CRLF,
          '.' . $CRLF];
}



sub schema1 {
  #fieldnames
  return [
          "301 List follows.\r\n",
          "Number\r\n",
          "Notify-List\r\n",
          "Category\r\n",
          "Synopsis\r\n",
          "Confidential\r\n",
          "Severity\r\n",
          "Priority\r\n",
          "Responsible\r\n",
          "State\r\n",
          "Class\r\n",
          "Submitter-Id\r\n",
          "Arrival-Date\r\n",
          "Closed-Date\r\n",
          "Last-Modified\r\n",
          "Originator\r\n",
          "Release\r\n",
          "Organization\r\n",
          "Environment\r\n",
          "Description\r\n",
          "How-To-Repeat\r\n",
          "Fix\r\n",
          "Release-Note\r\n",
          "Audit-Trail\r\n",
          "Unformatted\r\n",
          ".\r\n",

          #initialrequired
          "301 List follows.\r\n",
          ".\r\n",

          #initialinput
          "301 List follows.\r\n",
          "Submitter-Id\r\n",
          "Notify-List\r\n",
          "Originator\r\n",
          "Organization\r\n",
          "Synopsis\r\n",
          "Confidential\r\n",
          "Severity\r\n",
          "Priority\r\n",
          "Category\r\n",
          "Class\r\n",
          "Release\r\n",
          "Environment\r\n",
          "Description\r\n",
          "How-To-Repeat\r\n",
          "Fix\r\n",
          ".\r\n",

          #ftyp
          "350-Integer\r\n",
          "350-Text\r\n",
          "350-Enum\r\n",
          "350-Text\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Date\r\n",
          "350-Date\r\n",
          "350-Date\r\n",
          "350-Text\r\n",
          "350-Text\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350 MultiText\r\n",

          #fdsc
          "350-PR Number\r\n",
          "350-Addresses to notify of significant PR changes\r\n",
          "350-What area does this PR fall into?\r\n",
          "350-One-line summary of the PR\r\n",
          "350-Yes/no flag indicating if the PR contents are confidential\r\n",
          "350-How severe is the PR?\r\n",
          "350-How critical is it that the PR be fixed?\r\n",
          "350-The user responsible for the PR\r\n",
          "350-The current state of the PR\r\n",
          "350-The type of bug\r\n",
          "350-Site-specific identification of the PR author\r\n",
          "350-Arrival date of the PR\r\n",
          "350-Date when the PR was closed\r\n",
          "350-Last modification date of the PR\r\n",
          "350-Name of the PR author\r\n",
          "350-Release number or tag\r\n",
          "350-Organization of PR author\r\n",
          "350-Machine, OS, target, libraries\r\n",
          "350-Precise description of the problem\r\n",
          "350-Code/input/activities to reproduce the problem\r\n",
          "350-How to correct or work around the problem, if known\r\n",
          "350-\r\n",
          "350-Log of specific changes to the PR\r\n",
          "350 Miscellaneous text that was not parsed properly\r\n",

          #inputdefault
          "350--1\r\n",
          "350-\r\n",
          "350-pending\r\n",
          "350-\r\n",
          "350-yes\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-open\r\n",
          "350-sw-bug\r\n",
          "350-unknown\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\nUnknown\r\n",
          "350-\r\n",
          "350-\r\n",
          "350 \r\n",

          #fieldflags
          "350-readonly \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch allowAnyValue requireChangeReason \r\n",
          "350-textsearch requireChangeReason \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-readonly \r\n",
          "350-readonly \r\n",
          "350-readonly \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350 \r\n",];
}

1;
