package Module::Features::PerlTrove;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-02'; # DATE
our $DIST = 'Module-Features-PerlTrove'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %FEATURES_DEF;

# BEGIN FRAGMENT id=def
%FEATURES_DEF = %{( do {
  my $a = {
    features => {
      "Development Status" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "1 - Planning",
                                "2 - Pre-Alpha",
                                "3 - Alpha",
                                "4 - Beta",
                                "5 - Production/Stable",
                                "6 - Mature",
                                "7 - Inactive",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "Environment" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "Console",
                                "Console :: Curses",
                                "Console :: Framebuffer",
                                "Console :: Newt",
                                "Console :: svgalib",
                                "GPU",
                                "GPU :: NVIDIA CUDA",
                                "GPU :: NVIDIA CUDA :: 1.0",
                                "GPU :: NVIDIA CUDA :: 1.1",
                                "GPU :: NVIDIA CUDA :: 2.0",
                                "GPU :: NVIDIA CUDA :: 2.1",
                                "GPU :: NVIDIA CUDA :: 2.2",
                                "GPU :: NVIDIA CUDA :: 2.3",
                                "GPU :: NVIDIA CUDA :: 3.0",
                                "GPU :: NVIDIA CUDA :: 3.1",
                                "GPU :: NVIDIA CUDA :: 3.2",
                                "GPU :: NVIDIA CUDA :: 4.0",
                                "GPU :: NVIDIA CUDA :: 4.1",
                                "GPU :: NVIDIA CUDA :: 4.2",
                                "GPU :: NVIDIA CUDA :: 5.0",
                                "GPU :: NVIDIA CUDA :: 5.5",
                                "GPU :: NVIDIA CUDA :: 6.0",
                                "GPU :: NVIDIA CUDA :: 6.5",
                                "GPU :: NVIDIA CUDA :: 7.0",
                                "GPU :: NVIDIA CUDA :: 7.5",
                                "GPU :: NVIDIA CUDA :: 8.0",
                                "GPU :: NVIDIA CUDA :: 9.0",
                                "GPU :: NVIDIA CUDA :: 9.1",
                                "GPU :: NVIDIA CUDA :: 9.2",
                                "GPU :: NVIDIA CUDA :: 10.0",
                                "GPU :: NVIDIA CUDA :: 10.1",
                                "GPU :: NVIDIA CUDA :: 10.2",
                                "GPU :: NVIDIA CUDA :: 11.0",
                                "GPU :: NVIDIA CUDA :: 11.1",
                                "Handhelds/PDA's",
                                "MacOS X",
                                "MacOS X :: Aqua",
                                "MacOS X :: Carbon",
                                "MacOS X :: Cocoa",
                                "No Input/Output (Daemon)",
                                "OpenStack",
                                "Other Environment",
                                "Plugins",
                                "Web Environment",
                                "Web Environment :: Buffet",
                                "Web Environment :: Mozilla",
                                "Web Environment :: ToscaWidgets",
                                "Win32 (MS Windows)",
                                "X11 Applications",
                                "X11 Applications :: GTK",
                                "X11 Applications :: Gnome",
                                "X11 Applications :: KDE",
                                "X11 Applications :: Qt",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "Framework" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "AnyEvent",
                                "App::Cmd",
                                "Catalyst",
                                "CGI::Application",
                                "CHI",
                                "Dancer",
                                "Dancer2",
                                "Data::Printer",
                                "DateTime",
                                "DBI",
                                "DBIx::Class",
                                "Dist::Zilla",
                                "Gantry",
                                "HTML::FormFu",
                                "HTML::FormHandler",
                                "Interchange",
                                "IO::Async",
                                "Jifty",
                                "Log::Any",
                                "Log::Contextual",
                                "Log::Dispatch",
                                "Log::ger",
                                "Log::Log4perl",
                                "Mason",
                                "Maypole",
                                "Minilla",
                                "Mojolicious",
                                "Moo",
                                "Moose",
                                "Params::Validate",
                                "PDL",
                                "Perinci::CmdLine",
                                "POE",
                                "Sah",
                                "ShipIt",
                                "Specio",
                                "Template::Toolkit",
                                "Test2",
                                "Type::Tiny",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "Intended Audience" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "Customer Service",
                                "Developers",
                                "Education",
                                "End Users/Desktop",
                                "Financial and Insurance Industry",
                                "Healthcare Industry",
                                "Information Technology",
                                "Legal Industry",
                                "Manufacturing",
                                "Other Audience",
                                "Religion",
                                "Science/Research",
                                "System Administrators",
                                "Telecommunications Industry",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "License" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "Aladdin Free Public License (AFPL)",
                                "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication",
                                "CeCILL-B Free Software License Agreement (CECILL-B)",
                                "CeCILL-C Free Software License Agreement (CECILL-C)",
                                "DFSG approved",
                                "Eiffel Forum License (EFL)",
                                "Free For Educational Use",
                                "Free For Home Use",
                                "Free To Use But Restricted",
                                "Free for non-commercial use",
                                "Freely Distributable",
                                "Freeware",
                                "GUST Font License 1.0",
                                "GUST Font License 2006-09-30",
                                "Netscape Public License (NPL)",
                                "Nokia Open Source License (NOKOS)",
                                "OSI Approved",
                                "OSI Approved :: Academic Free License (AFL)",
                                "OSI Approved :: Apache Software License",
                                "OSI Approved :: Apple Public Source License",
                                "OSI Approved :: Artistic License",
                                "OSI Approved :: Attribution Assurance License",
                                "OSI Approved :: BSD License",
                                "OSI Approved :: Boost Software License 1.0 (BSL-1.0)",
                                "OSI Approved :: CEA CNRS Inria Logiciel Libre License, version 2.1 (CeCILL-2.1)",
                                "OSI Approved :: Common Development and Distribution License 1.0 (CDDL-1.0)",
                                "OSI Approved :: Common Public License",
                                "OSI Approved :: Eclipse Public License 1.0 (EPL-1.0)",
                                "OSI Approved :: Eclipse Public License 2.0 (EPL-2.0)",
                                "OSI Approved :: Eiffel Forum License",
                                "OSI Approved :: European Union Public Licence 1.0 (EUPL 1.0)",
                                "OSI Approved :: European Union Public Licence 1.1 (EUPL 1.1)",
                                "OSI Approved :: European Union Public Licence 1.2 (EUPL 1.2)",
                                "OSI Approved :: GNU Affero General Public License v3",
                                "OSI Approved :: GNU Affero General Public License v3 or later (AGPLv3+)",
                                "OSI Approved :: GNU Free Documentation License (FDL)",
                                "OSI Approved :: GNU General Public License (GPL)",
                                "OSI Approved :: GNU General Public License v2 (GPLv2)",
                                "OSI Approved :: GNU General Public License v2 or later (GPLv2+)",
                                "OSI Approved :: GNU General Public License v3 (GPLv3)",
                                "OSI Approved :: GNU General Public License v3 or later (GPLv3+)",
                                "OSI Approved :: GNU Lesser General Public License v2 (LGPLv2)",
                                "OSI Approved :: GNU Lesser General Public License v2 or later (LGPLv2+)",
                                "OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)",
                                "OSI Approved :: GNU Lesser General Public License v3 or later (LGPLv3+)",
                                "OSI Approved :: GNU Library or Lesser General Public License (LGPL)",
                                "OSI Approved :: Historical Permission Notice and Disclaimer (HPND)",
                                "OSI Approved :: IBM Public License",
                                "OSI Approved :: ISC License (ISCL)",
                                "OSI Approved :: Intel Open Source License",
                                "OSI Approved :: Jabber Open Source License",
                                "OSI Approved :: MIT License",
                                "OSI Approved :: MIT No Attribution License (MIT-0)",
                                "OSI Approved :: MITRE Collaborative Virtual Workspace License (CVW)",
                                "OSI Approved :: MirOS License (MirOS)",
                                "OSI Approved :: Motosoto License",
                                "OSI Approved :: Mozilla Public License 1.0 (MPL)",
                                "OSI Approved :: Mozilla Public License 1.1 (MPL 1.1)",
                                "OSI Approved :: Mozilla Public License 2.0 (MPL 2.0)",
                                "OSI Approved :: Nethack General Public License",
                                "OSI Approved :: Nokia Open Source License",
                                "OSI Approved :: Open Group Test Suite License",
                                "OSI Approved :: Open Software License 3.0 (OSL-3.0)",
                                "OSI Approved :: PostgreSQL License",
                                "OSI Approved :: Python License (CNRI Python License)",
                                "OSI Approved :: Python Software Foundation License",
                                "OSI Approved :: Qt Public License (QPL)",
                                "OSI Approved :: Ricoh Source Code Public License",
                                "OSI Approved :: SIL Open Font License 1.1 (OFL-1.1)",
                                "OSI Approved :: Sleepycat License",
                                "OSI Approved :: Sun Industry Standards Source License (SISSL)",
                                "OSI Approved :: Sun Public License",
                                "OSI Approved :: The Unlicense (Unlicense)",
                                "OSI Approved :: Universal Permissive License (UPL)",
                                "OSI Approved :: University of Illinois/NCSA Open Source License",
                                "OSI Approved :: Vovida Software License 1.0",
                                "OSI Approved :: W3C License",
                                "OSI Approved :: X.Net License",
                                "OSI Approved :: Zope Public License",
                                "OSI Approved :: zlib/libpng License",
                                "Other/Proprietary License",
                                "Public Domain",
                                "Repoze Public License",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "Natural Language" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "Afrikaans",
                                "Arabic",
                                "Basque",
                                "Bengali",
                                "Bosnian",
                                "Bulgarian",
                                "Cantonese",
                                "Catalan",
                                "Chinese (Simplified)",
                                "Chinese (Traditional)",
                                "Croatian",
                                "Czech",
                                "Danish",
                                "Dutch",
                                "English",
                                "Esperanto",
                                "Finnish",
                                "French",
                                "Galician",
                                "German",
                                "Greek",
                                "Hebrew",
                                "Hindi",
                                "Hungarian",
                                "Icelandic",
                                "Indonesian",
                                "Irish",
                                "Italian",
                                "Japanese",
                                "Javanese",
                                "Korean",
                                "Latin",
                                "Latvian",
                                "Lithuanian",
                                "Macedonian",
                                "Malay",
                                "Marathi",
                                "Nepali",
                                "Norwegian",
                                "Panjabi",
                                "Persian",
                                "Polish",
                                "Portuguese",
                                "Portuguese (Brazilian)",
                                "Romanian",
                                "Russian",
                                "Serbian",
                                "Slovak",
                                "Slovenian",
                                "Spanish",
                                "Swedish",
                                "Tamil",
                                "Telugu",
                                "Thai",
                                "Tibetan",
                                "Turkish",
                                "Ukrainian",
                                "Urdu",
                                "Vietnamese",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "Operating System" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "Android",
                                "BeOS",
                                "MacOS",
                                "MacOS :: MacOS 9",
                                "MacOS :: MacOS X",
                                "Microsoft",
                                "Microsoft :: MS-DOS",
                                "Microsoft :: Windows",
                                "Microsoft :: Windows :: Windows 3.1 or Earlier",
                                "Microsoft :: Windows :: Windows 7",
                                "Microsoft :: Windows :: Windows 8",
                                "Microsoft :: Windows :: Windows 8.1",
                                "Microsoft :: Windows :: Windows 10",
                                "Microsoft :: Windows :: Windows 95/98/2000",
                                "Microsoft :: Windows :: Windows CE",
                                "Microsoft :: Windows :: Windows NT/2000",
                                "Microsoft :: Windows :: Windows Server 2003",
                                "Microsoft :: Windows :: Windows Server 2008",
                                "Microsoft :: Windows :: Windows Vista",
                                "Microsoft :: Windows :: Windows XP",
                                "OS Independent",
                                "OS/2",
                                "Other OS",
                                "PDA Systems",
                                "POSIX",
                                "POSIX :: AIX",
                                "POSIX :: BSD",
                                "POSIX :: BSD :: BSD/OS",
                                "POSIX :: BSD :: FreeBSD",
                                "POSIX :: BSD :: NetBSD",
                                "POSIX :: BSD :: OpenBSD",
                                "POSIX :: GNU Hurd",
                                "POSIX :: HP-UX",
                                "POSIX :: IRIX",
                                "POSIX :: Linux",
                                "POSIX :: Other",
                                "POSIX :: SCO",
                                "POSIX :: SunOS/Solaris",
                                "PalmOS",
                                "RISC OS",
                                "Unix",
                                "iOS",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "Programming Language" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "APL",
                                "ASP",
                                "Ada",
                                "Assembly",
                                "Awk",
                                "Basic",
                                "C",
                                "C#",
                                "C++",
                                "Cold Fusion",
                                "Cython",
                                "Delphi/Kylix",
                                "Dylan",
                                "Eiffel",
                                "Emacs-Lisp",
                                "Erlang",
                                "Euler",
                                "Euphoria",
                                "F#",
                                "Forth",
                                "Fortran",
                                "Haskell",
                                "Java",
                                "JavaScript",
                                "Kotlin",
                                "Lisp",
                                "Logo",
                                "ML",
                                "Modula",
                                "OCaml",
                                "Object Pascal",
                                "Objective C",
                                "Other",
                                "Other Scripting Engines",
                                "PHP",
                                "PL/SQL",
                                "PROGRESS",
                                "Pascal",
                                "Perl",
                                "Pike",
                                "Pliant",
                                "Prolog",
                                "Python",
                                "Python :: 2",
                                "Python :: 2 :: Only",
                                "Python :: 2.3",
                                "Python :: 2.4",
                                "Python :: 2.5",
                                "Python :: 2.6",
                                "Python :: 2.7",
                                "Python :: 3",
                                "Python :: 3 :: Only",
                                "Python :: 3.0",
                                "Python :: 3.1",
                                "Python :: 3.2",
                                "Python :: 3.3",
                                "Python :: 3.4",
                                "Python :: 3.5",
                                "Python :: 3.6",
                                "Python :: 3.7",
                                "Python :: 3.8",
                                "Python :: 3.9",
                                "Python :: 3.10",
                                "Python :: Implementation",
                                "Python :: Implementation :: CPython",
                                "Python :: Implementation :: IronPython",
                                "Python :: Implementation :: Jython",
                                "Python :: Implementation :: MicroPython",
                                "Python :: Implementation :: PyPy",
                                "Python :: Implementation :: Stackless",
                                "R",
                                "REBOL",
                                "Rexx",
                                "Ruby",
                                "Rust",
                                "SQL",
                                "Scheme",
                                "Simula",
                                "Smalltalk",
                                "Tcl",
                                "Unix Shell",
                                "Visual Basic",
                                "XBasic",
                                "YACC",
                                "Zope",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "Topic" => {
        schema => [
          "any*",
          {
            of => [
                    [
                      "str*",
                      {
                        in => [
                                "Adaptive Technologies",
                                "Artistic Software",
                                "Communications",
                                "Communications :: BBS",
                                "Communications :: Chat",
                                "Communications :: Chat :: ICQ",
                                "Communications :: Chat :: Internet Relay Chat",
                                "Communications :: Chat :: Unix Talk",
                                "Communications :: Conferencing",
                                "Communications :: Email",
                                "Communications :: Email :: Address Book",
                                "Communications :: Email :: Email Clients (MUA)",
                                "Communications :: Email :: Filters",
                                "Communications :: Email :: Mail Transport Agents",
                                "Communications :: Email :: Mailing List Servers",
                                "Communications :: Email :: Post-Office",
                                "Communications :: Email :: Post-Office :: IMAP",
                                "Communications :: Email :: Post-Office :: POP3",
                                "Communications :: FIDO",
                                "Communications :: Fax",
                                "Communications :: File Sharing",
                                "Communications :: File Sharing :: Gnutella",
                                "Communications :: File Sharing :: Napster",
                                "Communications :: Ham Radio",
                                "Communications :: Internet Phone",
                                "Communications :: Telephony",
                                "Communications :: Usenet News",
                                "Database",
                                "Database :: Database Engines/Servers",
                                "Database :: Front-Ends",
                                "Desktop Environment",
                                "Desktop Environment :: File Managers",
                                "Desktop Environment :: GNUstep",
                                "Desktop Environment :: Gnome",
                                "Desktop Environment :: K Desktop Environment (KDE)",
                                "Desktop Environment :: K Desktop Environment (KDE) :: Themes",
                                "Desktop Environment :: PicoGUI",
                                "Desktop Environment :: PicoGUI :: Applications",
                                "Desktop Environment :: PicoGUI :: Themes",
                                "Desktop Environment :: Screen Savers",
                                "Desktop Environment :: Window Managers",
                                "Desktop Environment :: Window Managers :: Afterstep",
                                "Desktop Environment :: Window Managers :: Afterstep :: Themes",
                                "Desktop Environment :: Window Managers :: Applets",
                                "Desktop Environment :: Window Managers :: Blackbox",
                                "Desktop Environment :: Window Managers :: Blackbox :: Themes",
                                "Desktop Environment :: Window Managers :: CTWM",
                                "Desktop Environment :: Window Managers :: CTWM :: Themes",
                                "Desktop Environment :: Window Managers :: Enlightenment",
                                "Desktop Environment :: Window Managers :: Enlightenment :: Epplets",
                                "Desktop Environment :: Window Managers :: Enlightenment :: Themes DR15",
                                "Desktop Environment :: Window Managers :: Enlightenment :: Themes DR16",
                                "Desktop Environment :: Window Managers :: Enlightenment :: Themes DR17",
                                "Desktop Environment :: Window Managers :: FVWM",
                                "Desktop Environment :: Window Managers :: FVWM :: Themes",
                                "Desktop Environment :: Window Managers :: Fluxbox",
                                "Desktop Environment :: Window Managers :: Fluxbox :: Themes",
                                "Desktop Environment :: Window Managers :: IceWM",
                                "Desktop Environment :: Window Managers :: IceWM :: Themes",
                                "Desktop Environment :: Window Managers :: MetaCity",
                                "Desktop Environment :: Window Managers :: MetaCity :: Themes",
                                "Desktop Environment :: Window Managers :: Oroborus",
                                "Desktop Environment :: Window Managers :: Oroborus :: Themes",
                                "Desktop Environment :: Window Managers :: Sawfish",
                                "Desktop Environment :: Window Managers :: Sawfish :: Themes 0.30",
                                "Desktop Environment :: Window Managers :: Sawfish :: Themes pre-0.30",
                                "Desktop Environment :: Window Managers :: Waimea",
                                "Desktop Environment :: Window Managers :: Waimea :: Themes",
                                "Desktop Environment :: Window Managers :: Window Maker",
                                "Desktop Environment :: Window Managers :: Window Maker :: Applets",
                                "Desktop Environment :: Window Managers :: Window Maker :: Themes",
                                "Desktop Environment :: Window Managers :: XFCE",
                                "Desktop Environment :: Window Managers :: XFCE :: Themes",
                                "Documentation",
                                "Documentation :: Sphinx",
                                "Education",
                                "Education :: Computer Aided Instruction (CAI)",
                                "Education :: Testing",
                                "Games/Entertainment",
                                "Games/Entertainment :: Arcade",
                                "Games/Entertainment :: Board Games",
                                "Games/Entertainment :: First Person Shooters",
                                "Games/Entertainment :: Fortune Cookies",
                                "Games/Entertainment :: Multi-User Dungeons (MUD)",
                                "Games/Entertainment :: Puzzle Games",
                                "Games/Entertainment :: Real Time Strategy",
                                "Games/Entertainment :: Role-Playing",
                                "Games/Entertainment :: Side-Scrolling/Arcade Games",
                                "Games/Entertainment :: Simulation",
                                "Games/Entertainment :: Turn Based Strategy",
                                "Home Automation",
                                "Internet",
                                "Internet :: File Transfer Protocol (FTP)",
                                "Internet :: Finger",
                                "Internet :: Log Analysis",
                                "Internet :: Name Service (DNS)",
                                "Internet :: Proxy Servers",
                                "Internet :: WAP",
                                "Internet :: WWW/HTTP",
                                "Internet :: WWW/HTTP :: Browsers",
                                "Internet :: WWW/HTTP :: Dynamic Content",
                                "Internet :: WWW/HTTP :: Dynamic Content :: CGI Tools/Libraries",
                                "Internet :: WWW/HTTP :: Dynamic Content :: Content Management System",
                                "Internet :: WWW/HTTP :: Dynamic Content :: Message Boards",
                                "Internet :: WWW/HTTP :: Dynamic Content :: News/Diary",
                                "Internet :: WWW/HTTP :: Dynamic Content :: Page Counters",
                                "Internet :: WWW/HTTP :: Dynamic Content :: Wiki",
                                "Internet :: WWW/HTTP :: HTTP Servers",
                                "Internet :: WWW/HTTP :: Indexing/Search",
                                "Internet :: WWW/HTTP :: Session",
                                "Internet :: WWW/HTTP :: Site Management",
                                "Internet :: WWW/HTTP :: Site Management :: Link Checking",
                                "Internet :: WWW/HTTP :: WSGI",
                                "Internet :: WWW/HTTP :: WSGI :: Application",
                                "Internet :: WWW/HTTP :: WSGI :: Middleware",
                                "Internet :: WWW/HTTP :: WSGI :: Server",
                                "Internet :: XMPP",
                                "Internet :: Z39.50",
                                "Multimedia",
                                "Multimedia :: Graphics",
                                "Multimedia :: Graphics :: 3D Modeling",
                                "Multimedia :: Graphics :: 3D Rendering",
                                "Multimedia :: Graphics :: Capture",
                                "Multimedia :: Graphics :: Capture :: Digital Camera",
                                "Multimedia :: Graphics :: Capture :: Scanners",
                                "Multimedia :: Graphics :: Capture :: Screen Capture",
                                "Multimedia :: Graphics :: Editors",
                                "Multimedia :: Graphics :: Editors :: Raster-Based",
                                "Multimedia :: Graphics :: Editors :: Vector-Based",
                                "Multimedia :: Graphics :: Graphics Conversion",
                                "Multimedia :: Graphics :: Presentation",
                                "Multimedia :: Graphics :: Viewers",
                                "Multimedia :: Sound/Audio",
                                "Multimedia :: Sound/Audio :: Analysis",
                                "Multimedia :: Sound/Audio :: CD Audio",
                                "Multimedia :: Sound/Audio :: CD Audio :: CD Playing",
                                "Multimedia :: Sound/Audio :: CD Audio :: CD Ripping",
                                "Multimedia :: Sound/Audio :: CD Audio :: CD Writing",
                                "Multimedia :: Sound/Audio :: Capture/Recording",
                                "Multimedia :: Sound/Audio :: Conversion",
                                "Multimedia :: Sound/Audio :: Editors",
                                "Multimedia :: Sound/Audio :: MIDI",
                                "Multimedia :: Sound/Audio :: Mixers",
                                "Multimedia :: Sound/Audio :: Players",
                                "Multimedia :: Sound/Audio :: Players :: MP3",
                                "Multimedia :: Sound/Audio :: Sound Synthesis",
                                "Multimedia :: Sound/Audio :: Speech",
                                "Multimedia :: Video",
                                "Multimedia :: Video :: Capture",
                                "Multimedia :: Video :: Conversion",
                                "Multimedia :: Video :: Display",
                                "Multimedia :: Video :: Non-Linear Editor",
                                "Office/Business",
                                "Office/Business :: Financial",
                                "Office/Business :: Financial :: Accounting",
                                "Office/Business :: Financial :: Investment",
                                "Office/Business :: Financial :: Point-Of-Sale",
                                "Office/Business :: Financial :: Spreadsheet",
                                "Office/Business :: Groupware",
                                "Office/Business :: News/Diary",
                                "Office/Business :: Office Suites",
                                "Office/Business :: Scheduling",
                                "Other/Nonlisted Topic",
                                "Printing",
                                "Religion",
                                "Scientific/Engineering",
                                "Scientific/Engineering :: Artificial Intelligence",
                                "Scientific/Engineering :: Artificial Life",
                                "Scientific/Engineering :: Astronomy",
                                "Scientific/Engineering :: Atmospheric Science",
                                "Scientific/Engineering :: Bio-Informatics",
                                "Scientific/Engineering :: Chemistry",
                                "Scientific/Engineering :: Electronic Design Automation (EDA)",
                                "Scientific/Engineering :: GIS",
                                "Scientific/Engineering :: Human Machine Interfaces",
                                "Scientific/Engineering :: Hydrology",
                                "Scientific/Engineering :: Image Processing",
                                "Scientific/Engineering :: Image Recognition",
                                "Scientific/Engineering :: Information Analysis",
                                "Scientific/Engineering :: Interface Engine/Protocol Translator",
                                "Scientific/Engineering :: Mathematics",
                                "Scientific/Engineering :: Medical Science Apps.",
                                "Scientific/Engineering :: Physics",
                                "Scientific/Engineering :: Visualization",
                                "Security",
                                "Security :: Cryptography",
                                "Sociology",
                                "Sociology :: Genealogy",
                                "Sociology :: History",
                                "Software Development",
                                "Software Development :: Assemblers",
                                "Software Development :: Bug Tracking",
                                "Software Development :: Build Tools",
                                "Software Development :: Code Generators",
                                "Software Development :: Compilers",
                                "Software Development :: Debuggers",
                                "Software Development :: Disassemblers",
                                "Software Development :: Documentation",
                                "Software Development :: Embedded Systems",
                                "Software Development :: Internationalization",
                                "Software Development :: Interpreters",
                                "Software Development :: Libraries",
                                "Software Development :: Libraries :: Application Frameworks",
                                "Software Development :: Libraries :: Java Libraries",
                                "Software Development :: Libraries :: PHP Classes",
                                "Software Development :: Libraries :: Perl Modules",
                                "Software Development :: Libraries :: Pike Modules",
                                "Software Development :: Libraries :: Python Modules",
                                "Software Development :: Libraries :: Ruby Modules",
                                "Software Development :: Libraries :: Tcl Extensions",
                                "Software Development :: Libraries :: pygame",
                                "Software Development :: Localization",
                                "Software Development :: Object Brokering",
                                "Software Development :: Object Brokering :: CORBA",
                                "Software Development :: Pre-processors",
                                "Software Development :: Quality Assurance",
                                "Software Development :: Testing",
                                "Software Development :: Testing :: Acceptance",
                                "Software Development :: Testing :: BDD",
                                "Software Development :: Testing :: Mocking",
                                "Software Development :: Testing :: Traffic Generation",
                                "Software Development :: Testing :: Unit",
                                "Software Development :: User Interfaces",
                                "Software Development :: Version Control",
                                "Software Development :: Version Control :: Bazaar",
                                "Software Development :: Version Control :: CVS",
                                "Software Development :: Version Control :: Git",
                                "Software Development :: Version Control :: Mercurial",
                                "Software Development :: Version Control :: RCS",
                                "Software Development :: Version Control :: SCCS",
                                "Software Development :: Widget Sets",
                                "System",
                                "System :: Archiving",
                                "System :: Archiving :: Backup",
                                "System :: Archiving :: Compression",
                                "System :: Archiving :: Mirroring",
                                "System :: Archiving :: Packaging",
                                "System :: Benchmark",
                                "System :: Boot",
                                "System :: Boot :: Init",
                                "System :: Clustering",
                                "System :: Console Fonts",
                                "System :: Distributed Computing",
                                "System :: Emulators",
                                "System :: Filesystems",
                                "System :: Hardware",
                                "System :: Hardware :: Hardware Drivers",
                                "System :: Hardware :: Mainframes",
                                "System :: Hardware :: Symmetric Multi-processing",
                                "System :: Hardware :: Universal Serial Bus (USB)",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Audio",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Audio/Video (AV)",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Communications Device Class (CDC)",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Diagnostic Device",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Hub",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Human Interface Device (HID)",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Mass Storage",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Miscellaneous",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Printer",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Smart Card",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Vendor",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Video (UVC)",
                                "System :: Hardware :: Universal Serial Bus (USB) :: Wireless Controller",
                                "System :: Installation/Setup",
                                "System :: Logging",
                                "System :: Monitoring",
                                "System :: Networking",
                                "System :: Networking :: Firewalls",
                                "System :: Networking :: Monitoring",
                                "System :: Networking :: Monitoring :: Hardware Watchdog",
                                "System :: Networking :: Time Synchronization",
                                "System :: Operating System",
                                "System :: Operating System Kernels",
                                "System :: Operating System Kernels :: BSD",
                                "System :: Operating System Kernels :: GNU Hurd",
                                "System :: Operating System Kernels :: Linux",
                                "System :: Power (UPS)",
                                "System :: Recovery Tools",
                                "System :: Shells",
                                "System :: Software Distribution",
                                "System :: System Shells",
                                "System :: Systems Administration",
                                "System :: Systems Administration :: Authentication/Directory",
                                "System :: Systems Administration :: Authentication/Directory :: LDAP",
                                "System :: Systems Administration :: Authentication/Directory :: NIS",
                                "Terminals",
                                "Terminals :: Serial",
                                "Terminals :: Telnet",
                                "Terminals :: Terminal Emulators/X Terminals",
                                "Text Editors",
                                "Text Editors :: Documentation",
                                "Text Editors :: Emacs",
                                "Text Editors :: Integrated Development Environments (IDE)",
                                "Text Editors :: Text Processing",
                                "Text Editors :: Word Processors",
                                "Text Processing",
                                "Text Processing :: Filters",
                                "Text Processing :: Fonts",
                                "Text Processing :: General",
                                "Text Processing :: Indexing",
                                "Text Processing :: Linguistic",
                                "Text Processing :: Markup",
                                "Text Processing :: Markup :: HTML",
                                "Text Processing :: Markup :: LaTeX",
                                "Text Processing :: Markup :: Markdown",
                                "Text Processing :: Markup :: SGML",
                                "Text Processing :: Markup :: VRML",
                                "Text Processing :: Markup :: XML",
                                "Text Processing :: Markup :: reStructuredText",
                                "Utilities",
                              ],
                      },
                    ],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
      "Typing" => {
        schema => [
          "any*",
          {
            of => [
                    ["str*", { in => ["Typed"] }],
                    ["array*", { min_len => 1, of => ["str*", { in => 'fix' }] }],
                  ],
          },
        ],
      },
    },
    summary => "Perl trove classifiers",
    v => 1,
  };
  $a->{features}{"Development Status"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Development Status"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"Environment"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Environment"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"Framework"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Framework"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"Intended Audience"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Intended Audience"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"License"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"License"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"Natural Language"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Natural Language"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"Operating System"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Operating System"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"Programming Language"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Programming Language"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"Topic"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Topic"}{schema}[1]{of}[0][1]{in};
  $a->{features}{"Typing"}{schema}[1]{of}[1][1]{of}[1]{in} = $a->{features}{"Typing"}{schema}[1]{of}[0][1]{in};
  $a;
} )};

# END FRAGMENT id=def

1;
# ABSTRACT: Put Perl trove classifiers in your module

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Features::PerlTrove - Put Perl trove classifiers in your module

=head1 VERSION

This document describes version 0.003 of Module::Features::PerlTrove (from Perl distribution Module-Features-PerlTrove), released on 2021-04-02.

=head1 SYNOPSIS

To add Perl trove classifiers in your module, just define C<%FEATURES>
variable:

 package YourModule;
 #ABSTRACT: An App::Cmd application to highlight Indonesian words in text

 our %FEATURES = (
     features => {
         PerlTrove => {
             "Development Status" => "3 - Alpha",

             "Framework" => "App::Cmd",

             "Intended Audience" => "Developers",

             "License" => [
                 "OSI Approved :: Artistic License",
                 "OSI Approved :: GNU General Public License v2 or later (GPLv2+)",
             ],

             "Natural Language" => "Indonesian",

             "Programming Language" => "Perl",

             "Environment" => "Console",

             "Topic" => [
                 "Software Development :: Libraries :: Perl Modules",
                 "Text Processing :: Linguistic",
                 "Utilities",
             ],
         },

         # other features you might want to define
         # ...
     },
 };

To check whether your classifiers are valid (does not contain unknown
classifiers), you can use L<check-module-features> from
L<App::ModuleFeaturesUtils>:

 % check-module-features YourModule

To see the trove classifiers, you can use L<get-features-decl> from
L<App::ModuleFeaturesUtils>:

 % get-features-decl YourModule

There are other ways to read the trove classifiers, including accessing the
C<%FEATURES> variable directly.

=head1 DESCRIPTION

Perl trove classifiers are based on Python ones. Currently the only difference
is that the Python-specific framework classifiers in C<Framework :: *>, e.g.
C<Framework :: Django>, are replaced with Perl-specific ones, e.g. C<Framework
:: Dancer2>.

=head1 DEFINED FEATURES

Features defined by this module:

=over

=item * Development Status

Optional. Type: any. 

=item * Environment

Optional. Type: any. 

=item * Framework

Optional. Type: any. 

=item * Intended Audience

Optional. Type: any. 

=item * License

Optional. Type: any. 

=item * Natural Language

Optional. Type: any. 

=item * Operating System

Optional. Type: any. 

=item * Programming Language

Optional. Type: any. 

=item * Topic

Optional. Type: any. 

=item * Typing

Optional. Type: any. 

=back

For more details on module features, see L<Module::Features>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Features-PerlTrove>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Features-PerlTrove>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Module-Features-PerlTrove/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Features::PythonTrove>

L<Module::Features>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
