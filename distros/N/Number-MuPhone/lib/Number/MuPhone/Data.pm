package Number::MuPhone::Data;

# copied from Number::Phone::Country::Data and tweaked...

# forced single country on some code lookups. Since these are insignificant edge cases
# we can live with the commented out lines giving the wronmg country
%Number::MuPhone::Data::idd_codes = (
    # 1     => 'NANP',

    # 2* checked against wtng.info 2011-07-08
    20      => 'EG',
    211     => 'SS',
    #212     => ['MA', 'EH'],
    212     => 'MA',
    2125288 => 'EH', # \ from http://en.wikipedia.org/wiki/List_of_country_calling_codes#At_a_glance
    2125289 => 'EH', # /
    213     => 'DZ', 216     => 'TN',
    218     => 'LY', 220     => 'GM', 221     => 'SN', 222     => 'MR',
    223     => 'ML',
    224     => 'GN',
    225     => 'CI', 226     => 'BF', 227     => 'NE', 228     => 'TG',
    229     => 'BJ', 230     => 'MU', 231     => 'LR', 232     => 'SL',
    233     => 'GH', 234     => 'NG', 235     => 'TD', 236     => 'CF',
    237     => 'CM', 238     => 'CV',
    239     => 'ST', 240     => 'GQ', 241     => 'GA',
    242     => 'CG', 243     => 'CD', 244     => 'AO', 245     => 'GW',
    246     => 'IO', 247     => 'AC', 248     => 'SC', 249     => 'SD',
    250     => 'RW', 251     => 'ET', 252     => 'SO', 253     => 'DJ',
    254     => 'KE', 255     => 'TZ', 256     => 'UG', 257     => 'BI',
    258     => 'MZ', 260     => 'ZM', 261     => 'MG',
    262269  => 'YT', # Mayotte fixed lines
    262639  => 'YT', # Mayotte GSM
    #262     => ['RE', 'YT'],
    262     => 'RE',
    263     => 'ZW',
    264     => 'NA', 265     => 'MW', 266     => 'LS', 267     => 'BW',
    268     => 'SZ',
    269     => 'KM',
    # 27      => 'ZA', 290     => ['SH', 'TA'],
    27      => 'ZA', 290     => 'SH',
    291     => 'ER',
    297     => 'AW', 298     => 'FO', 299     => 'GL',

    # 3* checked against wtng.info 2011-07-08
    30      => 'GR', 31      => 'NL', 32      => 'BE', 33      => 'FR',
    34      => 'ES', 350     => 'GI', 351     => 'PT',
    352     => 'LU', 353     => 'IE', 35348   => 'GB', 354     => 'IS',
    #355     => 'AL', 356     => 'MT', 357     => 'CY', 358     => ['FI', 'AX'],
    355     => 'AL', 356     => 'MT', 357     => 'CY', 358     => 'FI',,
    359     => 'BG', 36      => 'HU', 370     => 'LT', 371     => 'LV',
    372     => 'EE', 373     => 'MD', 374     => 'AM', 375     => 'BY',
    376     => 'AD', 377     => 'MC',
    37744   => 'XK', # from http://en.wikipedia.org/wiki/List_of_country_calling_codes#At_a_glance
    37745   => 'XK',
    38128   => 'XK',
    38129   => 'XK',
    38138   => 'XK',
    38139   => 'XK',
    38643   => 'XK',
    38649   => 'XK',
    378     => 'SM', 379     => 'VA',
    380     => 'UA', 381     => 'RS',
    382     => 'ME', 385     => 'HR',
    383     => 'XK',
    386     => 'SI',
    387     => 'BA',
    # 389     => 'MK', 39      => ['IT', 'VA'], 3966982 => 'VA',
    389     => 'MK', 39      => 'IT', 3966982 => 'VA',

    # 4* checked against wtng.info 2011-07-08
    40      => 'RO', 41      => 'CH', 420     => 'CZ', 421     => 'SK',
    423     => 'LI',
    # 43      => 'AT', 44      => ['GB','GG', 'JE', 'IM'],
    43      => 'AT', 44      => 'UK',
    45      => 'DK', 46      => 'SE',
    # 47      => ['NO', 'BV', 'SJ'], 48      => 'PL', 49      => 'DE',
    47      => 'NO', 48      => 'PL', 49      => 'DE',

    # http://en.wikipedia.org/wiki/Telephone_numbers_in_the_United_Kingdom#Crown_dependencies
    441481 => 'GG', 447781 => 'GG', 447839 => 'GG', 447911 => 'GG',
    441534 => 'JE', 447509 => 'JE', 447797 => 'JE', 447937 => 'JE', 447700 => 'JE', 447829 => 'JE',
    441624 => 'IM', 447624 => 'IM', 447524 => 'IM', 447924 => 'IM',

    # 5* checked against wtng.info 2011-07-08
    # GS apparently shares (according to wikipedia) +500 with FK, but it's
    # unknown whether it actually has any phone service at all or whether
    # the handful of people there just use sat-phones
    # 500     => ['FK', 'GS'],
    500     => 'FK',
    501     => 'BZ', 502     => 'GT', 503     => 'SV', 504     => 'HN',
    505     => 'NI', 506     => 'CR', 507     => 'PA',
    508     => 'PM', 509     => 'HT',
    51      => 'PE', 52      => 'MX', 53      => 'CU', 54      => 'AR',
    55      => 'BR', 56      => 'CL', 57      => 'CO', 58      => 'VE',
    # http://en.wikipedia.org/wiki/Telephone_numbers_in_France#Overseas_Departments_and_Territories
    # 590     => ['GP', 'BL', 'MF'],
    590     => 'GP',
    591     => 'BO', 592     => 'GY', 593     => 'EC',
    # 594     => 'GF', 595     => 'PY', 596     => ['MQ', 'TF'], 597     => 'SR',
    594     => 'GF', 595     => 'PY', 596     => 'MQ', 597     => 'SR',
    598     => 'UY',
    # 599     => ['BQ', 'CW'],
    599     => 'BQ',
    5999    => 'CW',

    # 6* checked against wtng.info 2011-07-08
    60      => 'MY',
    # 61      => ['AU', 'CC', 'CX'],
    61      => 'AU',
    6189162 => 'CC', # Cocos (Keeling) Islands
    6189164 => 'CX', # Christmas Island
    62      => 'ID', 63      => 'PH',
    64      => 'NZ', 65      => 'SG', 66      => 'TH', 670     => 'TL',
    # 672     => ['AQ', 'NF'],
    672     => 'AQ',
    67210   => 'AQ', # Davis station    \
    67211   => 'AQ', # Mawson           | Australian Antarctic bases
    67212   => 'AQ', # Casey            |
    67213   => 'AQ', # Macquarie Island /
    6723    => 'NF', # Norfolk Island
    673     => 'BN', 674     => 'NR', 675     => 'PG', 676     => 'TO',
    677     => 'SB', 678     => 'VU', 679     => 'FJ', 680     => 'PW',
    681     => 'WF', 682     => 'CK',
    683     => 'NU', 685     => 'WS', 686     => 'KI', 687     => 'NC',
    688     => 'TV',
    689     => 'PF', 690     => 'TK', 691     => 'FM', 692     => 'MH',

    # 7* from http://en.wikipedia.org/wiki/Telephone_numbers_in_Kazakhstan
    # checked 2011-07-08
    76      => 'KZ',
    77      => 'KZ',
    # 7       => ['RU', 'KZ'],
    7       => 'RU',

    # 8* checked against wtng.info 2011-07-08
    81      => 'JP', 82      => 'KR', 84      => 'VN', 850     => 'KP',
    852     => 'HK', 853     => 'MO', 855     => 'KH', 856     => 'LA',
    86      => 'CN',
    880     => 'BD',
    886     => 'TW',

    # 9* checked against wtng.info 2011-07-08
    90      => 'TR', 91      => 'IN', 92      => 'PK', 93      => 'AF',
    94      => 'LK', 95      => 'MM', 960     => 'MV', 961     => 'LB',
    962     => 'JO', 963     => 'SY', 964     => 'IQ', 965     => 'KW',
    966     => 'SA', 967     => 'YE', 968     => 'OM', 970     => 'PS',
    971     => 'AE',
    972     => 'IL', 973     => 'BH', 974     => 'QA', 975     => 'BT',
    976     => 'MN', 977     => 'NP',
    98      => 'IR',
    992     => 'TJ',
    993     => 'TM', 994     => 'AZ', 995     => 'GE',
    996     => 'KG', 998     => 'UZ',

    # these checked against wtng.info 2011-07-08
    # https://en.wikipedia.org/wiki/Global_Mobile_Satellite_System
    # https://en.wikipedia.org/wiki/International_Networks_%28country_code%29
    800     => 'InternationalFreephone',
    808     => 'SharedCostServices',
    870     => 'Inmarsat',
    871     => 'Inmarsat',
    872     => 'Inmarsat',
    873     => 'Inmarsat',
    874     => 'Inmarsat',
    878     => 'UniversalPersonalTelecoms',
    881     => 'GMSS',       # \ Sat-phones
    8810    => 'ICO',        # |
    8811    => 'ICO',        # |
    8812    => 'Ellipso',    # |
    8813    => 'Ellipso',    # |
    # 8814 is spare          # |
    # 8815 is spare          # |
    8816    => 'Iridium',    # |
    8817    => 'Iridium',    # |
    8818    => 'Globalstar', # |
    8819    => 'Globalstar', # /
    882     => 'InternationalNetworks',
    883     => 'InternationalNetworks',
    883120  => 'Telenor',
    883130  => 'Mobistar',
    883140  => 'MTTGlobalNetworks',
    8835100 => 'VOXBON',
    888     => 'TelecomsForDisasterRelief',
    # 979 is used for testing when we fail to load a module when we
    # know what "country" it is
    979     => 'InternationalPremiumRate',
    991     => 'ITPCS',
    # 999 deliberately NYI for testing; proposed to be like 888.
);

%Number::MuPhone::Data::NANP_areas = (
  (
    map { $_ => 'CA' } qw(
      204 226 236 249 250 289 306 343 365 403 416 418 431 437 438 450 506
      514 519 548 579 581 587 604 613 639 647 705 709 778 780 782 807 819
      825 867 873 902 905 600 622 633 644 655 677 688
    )
  ),
  (
    # from http://www.nanpa.com/enas/geoAreaCodeAlphabetReport.do, 2014-04-20
    map { $_ => 'US' } qw(
       907 334 938 256 251 205 870 479 501 520 480 928 602 623 619 562 650
       657 661 408 415 424 442 626 559 530 510 323 310 951 949 925 209 213
       669 707 714 747 760 805 818 831 858 909 916 303 970 720 719 203 475
       860 202 302 407 561 727 754 772 786 813 850 863 904 941 954 305 321
       352 386 239 404 229 762 470 678 706 478 770 912 808 712 319 641 563
       515 208 708 224 217 618 630 331 312 309 872 847 773 779 815 317 219
       812 574 260 765 913 316 785 620 502 859 364 270 606 225 985 504 337
       318 857 781 774 978 413 339 351 508 617 240 301 410 667 443 207 248
       947 810 989 517 734 313 231 269 586 906 616 763 218 651 612 507 320
       952 636 573 314 417 816 660 769 601 228 662 406 252 704 828 910 919
       980 984 336 701 308 402 603 732 856 862 908 973 201 609 848 551 575
       505 775 702 914 718 929 845 212 315 347 646 585 631 516 518 607 716
       917 614 567 513 330 937 740 234 216 440 419 918 405 539 580 971 541
       503 458 610 412 215 717 724 814 484 570 878 267 272 401 843 864 803
       605 931 615 901 865 423 731 713 737 806 817 512 832 903 915 940 956
       972 979 936 281 325 361 682 254 214 210 469 432 430 409 830 385 435
       801 434 703 757 571 804 276 540 802 360 253 206 425 509 262 920 534
       414 608 715 304 681 307 710
    )
  ),
  787 => 'PR', 939 => 'PR',
  # see http://wtng.info/wtng-cod.html#WZ1
  # checked 2014-04-21
  809 => 'DO',     829 => 'DO',     849 => 'DO',    242 => 'BS',
  246 => 'BB',     264 => 'AI',     268 => 'AG',    284 => 'VG',
  340 => 'VI',     345 => 'KY',     441 => 'BM',    473 => 'GD',
  649 => 'TC',     664 => 'MS',     670 => 'MP',    671 => 'GU',
  684 => 'AS',     721 => 'SX',     758 => 'LC',    767 => 'DM',
  784 => 'VC',     868 => 'TT',     869 => 'KN',    876 => 'JM',
);

