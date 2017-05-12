### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto Demonstration GUI
#    Copyright (C) 2000-2017  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################

use Term::Menus;

   my $demo_banner=<<'END';

                              ___     _ _   _       _
                             | __|  _| | | /_\ _  _| |_ ___
   (   /_ /_   _  _          | _| || | | |/ _ \ || |  _/ _ \
   |/|/(-(( ()//)(-  To The  |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
    ___                        _            _   _
   |   \ ___ _ __  ___ _ _  __| |_ _ _ __ _| |_(_)___ _ _
   | |) / -_) '  \/ _ \ ' \(_-<  _| '_/ _` |  _| / _ \ ' \
   |___/\___|_|_|_\___/_||_/__/\__|_| \__,_|\__|_\___/_||_|
   --------------------------------------------------------

   If you are new to FullAuto, and would like a better idea of what it
   is and what it does, please explore this brief introduction. You can
   access the introduction by just pressing [ENTER]

   Otherwise, use the DOWN ARROW [v] key to move the arrow to item 2
   and press [ENTER] - or just type 2 and press [ENTER] to exit this
   dialogue.

END

   my $demo_banner_1=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___
   | _| || | | |/ _ \ || |  _/ _ \
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
    ___     _               _         _   _
   |_ _|_ _| |_ _ _ ___  __| |_  _ __| |_(_)___ _ _
    | || ' \  _| '_/ _ \/ _` | || / _|  _| / _ \ ' \
   |___|_||_\__|_| \___/\__,_|\_,_\__|\__|_\___/_||_|
   --------------------------------------------------
   FullAuto is a breakthrough innovation in Network Process Automation.
   Any time a process involves more than one device, it is a "networked"
   process. Anyone who uses the Internet, engages in "network processing"
   - it's called ... SURFING! The key to rapid, inexpensive yet infinitely
   powerful and scalable network process automation is a SECURE and
    _  __ _  __  __ ___ __    ___
   |_)|_ |_)(_ |(_   | |_ |\ | |
   |  |__| \__)|__)  | |__| \| | connection to the command-line environments
   of remote devices. The Internet is in fact BILLIONS of connected devices.

   Browsers however, do NOT have direct access to the command-line
   functionality of remote devices, nor are they supposed to.
END

   my $demo_banner_2=<<'END';

   This is precisely why you are *not* reading this in a browser.
   -------------------------------------------------------------

   FullAuto is an Automation and High Productivity Framework - it is *NOT*
   a browser - nor is it "supposed" to be. But that doesn't mean it has to
   be ...
               .-'''-.                                        ___
              '   _    \                                   .'/   \
   /|       /   /` '.   \         .--.   _..._            / /     \
   ||      .   |     \  '         |__| .'     '.   .--./) | |     |
   ||      |   '      |  '.-,.--. .--..   .-.   . /.''\\  | |     |
   ||  __  \    \     / / |  .-. ||  ||  '   '  || |  | | |/`.   .'
   ||/'__ '.`.   ` ..' /  | |  | ||  ||  |   |  | \`-' /   `.|   |
   |:/`  '. '  '-...-'`   | |  | ||  ||  |   |  | /("'`     ||___|
   ||     | |             | |  '- |  ||  |   |  | \ '---.   |/___/
   ||\    / '             | |     |__||  |   |  |  /'""'.\  .'.--.
   |/\'..' /              | |         |  |   |  | ||     ||| |    |
   '  `'-'`               |_|         |  |   |  | \'. __// \_\    /
                                      '--'   '--'  `'---'   `''--'
END

   my $demo_banner_3=<<'END';

                        (                   (        )   ____
                        )\ )   (     (      )\ )  ( /(  |   /
                       (()/(   )\    )\    (()/(  )\()) |  /
                        /(_))(((_)((((_)(   /(_))((_)\  | /
                       (_))  )\___ )\ _ )\ (_)) __ ((_) |/
           ___ _ _     / __|((/ __|(_)_\(_)| _ \\ \ / /(
          / _ \ '_|    \__ \ | (__  / _ \  |   / \ V / )\
          \___/_|      |___/  \___|/_/ \_\ |_|_\  |_| ((_)


 BECAUSE you don't have to . . .

  ____ ____ ____ ____ ____ ____ ____ ____     ___     _ _   _       _
 ||R |||E |||M |||E |||M |||B |||E |||R ||   | __|  _| | | /_\ _  _| |_ ___
 ||__|||__|||__|||__|||__|||__|||__|||__||   | _| || | | |/ _ \ || |  _/ _ \
 |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
  ____ ____ ____ ____ ____ ____ ____ ____
 ||C |||O |||M |||M |||A |||N |||D |||S ||    _  _  __ __  ______   _
 ||__|||__|||__|||__|||__|||__|||__|||__||   | \/ \|_ (_    |  |   |_||  |
 |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|   |_/\_/|____)  _|_ |   | ||__|__
END

   my $demo_banner_4=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___
   | _| || | | |/ _ \ || |  _/ _ \
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)

      _  _   _ _____ ___  __  __   _ _____ ___ ___
     /_\| | | |_   _/ _ \|  \/  | /_\_   _| __/ __|
    / _ \ |_| | | || (_) | |\/| |/ _ \| | | _|\__ \
   /_/ \_\___/  |_| \___/|_|  |_/_/ \_\_| |___|___/  THE

    #####   ###     #####   ##  ## #####     FASTER,
   #######  ###    ### ### ### ###  #####    EASIER,
   ### # #  ###    ### ### ### ###  ## ###   with more,
   ##      ###     ##   ## ##  ###  ##  ##   VISIBILITY,
   ##      ###     ##   ## ###  ## ###  ##   more PRECISION,
   ### # # ### ### ### ### ### ### ### ###   more CUSTOMIZABLE,
   ####### ####### ####### ####### ######    LESS COST, and MORE RESULTS than
    #####   #####   #####   #####  #####     any other technology AVAILABLE!!

END

   my $demo_banner_5=<<'END';


     __    _____ _____ / __    '########::'########::::'###::::'##:::::::
     ||    ||==   ||    ((      ##.... ##: ##.....::::'## ##::: ##:::::::
     ||__| ||___  ||   \_))     ##:::: ##: ##::::::::'##:. ##:: ##:::::::
                                ########:: ######:::'##:::. ##: ##:::::::
      ____  _____ _____         ##.. ##::: ##...:::: #########: ##:::::::
     (( ___ ||==   ||           ##::. ##:: ##::::::: ##.... ##: ##:::::::
      \\_|| ||___  ||           ##:::. ##: ########: ##:::: ##: ########:
                               ..:::::..::........::..:::::..::........::

   The *CLOUD* is nothing more than REMOTE DEVICES. FULL Automation of
   the *CLOUD* means FULL remote control of these devices. To achieve
   that, a tool requires FULL, PERSISTENT and SECURE access to a remote
   device's command-line environment. Computer Professionals typically
   use tools like SSH (Secure Shell) and SFTP (Secure FTP) to gain full
   access to remote command-line environments. These utilities are already
   installed on billions of devices globally, or can be easily installed
   for FREE on nearly EVERY network connected device in existence -
   including smart phones and tablets!
END

   my $demo_banner_6=<<'END';

        ___     _ _   _       _
       | __|  _| | | /_\ _  _| |_ ___
       | _| || | | |/ _ \ || |  _/ _ \
   THE |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
    ______                    _           _                            _
   (____  \                  | |      _  | |                          | |
    ____)  ) ____ _____ _____| |  _ _| |_| |__   ____ ___  _   _  ____| |__
   |  __  ( / ___) ___ (____ | |_/ |_   _)  _ \ / ___) _ \| | | |/ _  |  _ \
   | |__)  ) |   | ____/ ___ |  _ (  | |_| | | | |  | |_| | |_| ( (_| | | | |
   |______/|_|   |_____)_____|_| \_)  \__)_| |_|_|   \___/|____/ \___ |_| |_|
                                                                (_____|
   Current automation technologies do not typically use generic and readily
   available utilities designed for human interaction - like the command
   shell you are now using for this demonstration. Rather they rely on an
   architecture known as client-server. The problem with client-server is
   that special (and often VERY costly) software needs to be installed on
   *EVERY* device BEFORE it can be accessed and automated. This very
   requirement is one of the biggest productivity obstables to rapid
   automation implementation. Additionally, client-server setups are much
   more complex, fragile, and challenging to code and maintain than FullAuto!
END

   my $demo_banner_7=<<'END';

        ___     _ _   _       _
       | __|  _| | | /_\ _  _| |_ ___
       | _| || | | |/ _ \ || |  _/ _ \
   THE |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
       ____  _ ________
      / __ \(_) __/ __/__  ________  ____  ________
     / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ ___/ _ \
    / /_/ / / __/ __/  __/ /  /  __/ / / / /__/  __/
   /_____/_/_/ /_/  \___/_/   \___/_/ /_/\___/\___/

   FullAuto uses already available SSH and SFTP services to FULLY automate
   command operations on remote devices. The DIFFERENCE lies in *HOW* FullAuto
   connects to and uses these services. Unlike any other technology, FullAuto
   creates and maintains a PERSISENT connection via these protocols, and
   even older ones like TELNET and FTP. Current SSH 2.0 implementations can
   be configured to allow similar behavior, but it varies from device to
   device, and is not widely available. FullAuto has NO such dependency. If
   a SSH client (or TELNET or SFTP or FTP) of ANY kind can connect to the
   device, FUllAuto can connect to it as well - PERSISTENTLY.

END

   my $demo_banner_8=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___
   | _| || | | |/ _ \ || |  _/ _ \
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
    __    __ _              _____ _                  _   _
   / / /\ \ \ |__  _   _    \_   \ |_    /\/\   __ _| |_| |_ ___ _ __ ___
   \ \/  \/ / '_ \| | | |    / /\/ __|  /    \ / _` | __| __/ _ \ '__/ __|
    \  /\  /| | | | |_| | /\/ /_ | |_  / /\/\ \ (_| | |_| ||  __/ |  \__ \
     \/  \/ |_| |_|\__, | \____/  \__| \/    \/\__,_|\__|\__\___|_|  |___/
                   |___/
   For the very first time, there is now an automation tool that works just
   like computer professionals do. The very same commands and work-flows
   that professionals use every day can now be introduced almost verbatim
   into a FullAuto custom code file, and work precisely the same as if
   performed manually. FullAuto leverages the skillsets and legacy tools
   and scripts already in place in countless organizations all over the
   world - and simply connects them ALL together like never before. The
   result is faster automation implementation, eaiser maintainability, and
   significantly lower costs. Staff will spend less time on repetitive
   tasks, and more time on innovation.
END

   my $demo_banner_9=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___
   | _| || | | |/ _ \ || |  _/ _ \
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
      _             _   __    __ _                 __               ___
     /_\  _ __   __| | / / /\ \ \ |__  _   _    /\ \ \_____      __/ _ \
    //_\\| '_ \ / _` | \ \/  \/ / '_ \| | | |  /  \/ / _ \ \ /\ / /\// /
   /  _  \ | | | (_| |  \  /\  /| | | | |_| | / /\  / (_) \ V  V /   \/
   \_/ \_/_| |_|\__,_|   \/  \/ |_| |_|\__, | \_\ \/ \___/ \_/\_/    ()
                                       |___/
   False assumptions. The "experts" thought a tool like FullAuto was not
   possible. The assumption was because output from a generic connection
   could have INFINITE variation (TRUE), that there was "no way" to create
   a solution that could successfully separate transmission noise from
   valid command-line output and error output (which makes unpredictable
   appearances in the output). Running one command programmatically has
   never been an issue - but the goal of running MULTIPLE commands
   INTERACTIVELY over a PERSISENT "generic" (i.e., not client-server)
   connection - was assumed to be **impossible**. (FALSE!!)

END

   my $demo_banner_10=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___      ___    __   __     _  __ _ ___ __
   | _| || | | |/ _ \ || |  _/ _ \      | |_||_   |_  \/ |_)|_ |_) | (_
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)   | | ||__  |__ /\ |  |__| \ | __)

   __      _____ ___ ___     _      _____  ____  _  _______  __
   \ \    / / __| _ \ __|   | | /| / / _ \/ __ \/ |/ / ___/ / /
    \ \/\/ /| _||   / _|    | |/ |/ / , _/ /_/ /    / (_-- /_/
     \_/\_/ |___|_|_\___|   |__/|__/_/|_|\____/_/|_/\____/(_)

   Not the first time in history this has happened. There is no technical
   reason that a tool like FullAuto could not have been created 30 years
   ago, but for the false belief that it wasn't possible. Experts will
   generally not spend their time trying to solve "impossible" problems.
   Not until Brian Kelly has anyone apparently thought any differently.
   Kelly conceived of FullAuto as early as 1998, and began active
   development in 2000. However, it would take 15 LONG years to make it
   a reality. The experts were wrong - but they weren't crazy. The
   problem was not trivial, and the solution is not either!

END

   my $demo_banner_11=<<'END';

   People typically use utilities like SSH and SFTP to access the
   command-line environments of remote devices. These utilities are
   already installed on millions of devices globally, or can be easily
   installed for FREE on mearly EVERY networked device - including phones
   and tablets.

   Programs however, typically rely on client-server architecture,
   which requires that special software be installed on *EVERY*
   device BEFORE it can be accessed and automated.

   "Technically", ssh and sftp are also "client-server". The critical
   difference is that these programs are *NOT* "special".



   As long as a device can be remotely connected to via ssh, sftp,
   telnet, ftp, http or really, ANY remote computing protocol,
   FullAuto can completely automate any and all activities on that
   device, and other devices all simultaneously and persistently.

   Essentially, whatever a person can do on and with a device
   "manually" - FullAuto can do PROGRAMMATICALLY ... securely.

END

   my %fullauto_demo_10=(

      Name => 'fullauto_demo_10',
      Banner => $demo_banner_10,
      Result => sub { return '{fullauto_demo}<' },

   );

   my %fullauto_demo_9=(

      Name => 'fullauto_demo_9',
      Banner => $demo_banner_9,
      Result => \%fullauto_demo_10,

   );

   my %fullauto_demo_8=(

      Name => 'fullauto_demo_8',
      Banner => $demo_banner_8,
      Result => \%fullauto_demo_9,

   );

   my %fullauto_demo_7=(

      Name => 'fullauto_demo_7',
      Banner => $demo_banner_7,
      Result => \%fullauto_demo_8,

   );

   my %fullauto_demo_6=(

      Name => 'fullauto_demo_6',
      Banner => $demo_banner_6,
      Result => \%fullauto_demo_7,

   );

   my %fullauto_demo_5=(

      Name => 'fullauto_demo_5',
      Banner => $demo_banner_5,
      Result => \%fullauto_demo_6,

   );

   my %fullauto_demo_4=(

      Name => 'fullauto_demo_4',
      Banner => $demo_banner_4,
      Result => \%fullauto_demo_5,

   );

   my %fullauto_demo_3=(

      Name => 'fullauto_demo_3',
      Banner => $demo_banner_3,
      Result => \%fullauto_demo_4,

   );

   my %fullauto_demo_2=(

      Name => 'fullauto_demo_2',
      Banner => $demo_banner_2,
      Result => \%fullauto_demo_3,

   );

   my %fullauto_demo_1=(

      Name => 'fullauto_demo_1',
      Banner => $demo_banner_1,
      Result => \%fullauto_demo_2,

   );

   my %fullauto_demo=(

      Name => 'fullauto_demo',
      Item_1 => {

         Text => "FullAuto Introduction",
         Result => \%fullauto_demo_1,

      },
      Item_2 => {

         Text => "Exit this Dialogue",

      },
      Scroll => 1,
      Banner => $demo_banner,

   );


   my $demo_out=Menu(\%fullauto_demo);
   exit;
