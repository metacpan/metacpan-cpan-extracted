#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 199;
use Math::BigInt;

use Support qw(test_trace);

use constant TRACES => {
    # Multiple Threads, No Symbols, Signal Handler
    'ekiga-bug-364113' => {
        threads => 10,
        thread  => 1,
        frames  => 25,
        crash_frame => 3,
        description => 'Thread -1247730000 (LWP 5645)',
        trace_lines => 343,
    },
    # Single Thread, Symbols, Signal Handler
    'gnumeric-bug-127364' => {
        threads => 1,
        thread  => 1,
        frames  => 42,
        crash_frame => 5,
        description => 'Thread 16384 (LWP 9708)',
        trace_lines => 835,
    },
    # Single un-named thread, extra newline in an "args" section,
    # whole file is trace, no signal handler
    'gnome-bug-10228' => {
        threads     => 1,
        thread      => 1,
        frames      => 39,
        trace_lines => 143,
    },
    # Really poor trace with almost no information in most frames.
    # Ends in an ignored line.
    'gnome-bug-20861' => {
        threads => 1,
        thread  => 1,
        frames  => 50,
        trace_lines => 58,
    },
    # Contains weird <blah, blah>::blah function syntax (C++)
    'gnome-bug-33996' => {
        threads => 1,
        thread => 1,
        frames => 11,
        trace_lines => 19,
        stack => [qw(
            __wait4
            __DTOR_END__
            waitpid
            gnome_segv_handle
            pthread_sighandler),
            '<signal handler called>',
            'WelcomeDruid::Connected',
            'GabberWin::OnSessionConnected',
            'SigC::ObjectSlot1_<void, judo::Tag const &, GabberWin>::callback',
            'SigC::Signal1<void, judo::Tag const &, SigC::Marshal<void> >::emit',
            'jabberoo::Session::IQHandler_Auth',
        ],
    },
    # Contains "type_info node" functions
    'gnome-bug-28596' => {
        threads => 1,
        thread  => 1,
        frames  => 83,
        trace_lines => 133,
    },
    # Contains frame lines that legitimately end with (
    'gnome-bug-2742' => {
        threads => 1,
        thread  => 1,
        frames  => 4,
        trace_lines => 4,
        stack => [qw(
            g_on_error_stack_trace
            g_on_error_query
            gimp_request_wakeups),
            '<signal handler called>'
        ],
    },
    # Contains gdb command lines and "hit return to continue" prompt
    'gnome-bug-589922' => {
        threads => 1,
        thread  => 1,
        frames  => 77,
        trace_lines => 118,
    },
    # Enormous trace, contains stuff like "non-virtual thunk to" as part of
    # functions. Also has () immediately after the function name to denote
    # what the parameter types are for the C++ function, for one frame.
    'gnome-bug-580218' => {
        threads => 10,
        thread  => 6,
        frames  => 6,
        trace_lines => 743,
        stack => [qw(
            __kernel_vsyscall
            poll
            _pr_poll_with_poll
            nsSocketTransportService::AddToPollList),
            'non-virtual thunk to nsSocketTransportService::QueryInterface(nsID const&, void**)',
            '??'
        ],
    },
    # Starts threads with "[Switching to Thread" and has a < > at the end of
    # a function without a ::something after it.
    'gnome-bug-580868' => {
        threads => 2,
        thread  => Math::BigInt->new('0x7f402c6ff750'),
        frames  => 13,
        description => 'LWP 22946',
        trace_lines => 102,
        thread_array_pos => 1,
        stack => [qw(
            raise
            abort
            __gnu_cxx::__verbose_terminate_handler
            __cxxabiv1::__terminate
            std::terminate
            __cxa_throw
            boost::throw_exception<boost::io::bad_format_string>
            boost::io::detail::maybe_throw_exception),
            'boost::io::detail::parse_printf_directive<char, std::char_traits<char>, std::allocator<char>, __gnu_cxx::__normal_iterator<char const*, std::string>, std::ctype<char> >',
            'boost::basic_format<char, std::char_traits<char>, std::allocator<char> >::parse',
            'boost::basic_format<char, std::char_traits<char>, std::allocator<char> >::basic_format',
            'gnote::NoteRecentChanges::update_match_note_count',
            'gnote::NoteRecentChanges::perform_search',
        ],
    },
    # Contains a thread with @plt after the function name.
    'gnome-bug-581998' => {
        threads => 2,
        thread  => 1,
        frames  => 10,
        description => 'Thread 0xb663f6d0 (LWP 3233)',
        trace_lines => 98,
        stack => [qw(
            __kernel_vsyscall
            waitpid
            IA__g_spawn_sync
            IA__g_spawn_command_line_sync
            ??
            ??
            segv_redirect),
            '<signal handler called>',
            '__cxa_finalize',
            '??'
        ],
    },
    # Has a frame that has both <> and () on the function itself. Also has
    # crazy long lines with lots of function-name craziness.
    'gnome-bug-586069' => {
        threads => 14,
        thread  => 1,
        frames  => 24,
        trace_lines => 753,
        stack => [qw(
            *__GI___poll
            send_dg
            __libc_res_nsend
            *__GI___libc_res_nquery
            __libc_res_nquerydomain
            __libc_res_nsearch),
            'DnsQuery_A(char const*, unsigned short, unsigned int, _IP4_ARRAY*, DnsRecord**, void*)',
            'bool PDNS::Lookup<33u, PDNS::SRVRecordList, PDNS::SRVRecord>(PString const&, PDNS::SRVRecordList&)',
            'PDNS::LookupSRV(PString const&, unsigned short, std::vector<PIPSocketAddressAndPort, std::allocator<PIPSocketAddressAndPort> >&)',
            'PDNS::LookupSRV(PString const&, PString const&, unsigned short, std::vector<PIPSocketAddressAndPort, std::allocator<PIPSocketAddressAndPort> >&)',
            'SIPURL::AdjustToDNS(int)',
            'SIPTransaction::Start()',
            'SIPHandler::WriteSIPHandler(OpalTransport&)',
            'OpalTransportUDP::WriteConnect(bool (*)(OpalTransport&, void*), void*)',
            'SIPHandler::SendRequest(SIPHandler::State)',
            'SIPEndPoint::Publish(SIPSubscribe::Params const&, PString const&, PString&)',
            'SIPEndPoint::Publish(PString const&, PString const&, unsigned int)',
            'Opal::Sip::EndPoint::publish(Ekiga::PersonalDetails const&)',
            'Ekiga::PresenceCore::publish(gmref_ptr<Ekiga::PersonalDetails>)',
            'Ekiga::PresenceCore::on_registration_event(gmref_ptr<Ekiga::Bank>, gmref_ptr<Ekiga::Account>, Ekiga::Account::RegistrationState, std::string, gmref_ptr<Ekiga::PersonalDetails>)',
            'sigc::internal::slot_call4<sigc::bind_functor<-1, sigc::bound_mem_functor5<void, Ekiga::PresenceCore, gmref_ptr<Ekiga::Bank>, gmref_ptr<Ekiga::Account>, Ekiga::Account::RegistrationState, std::string, gmref_ptr<Ekiga::PersonalDetails> >, gmref_ptr<Ekiga::PersonalDetails>, sigc::nil, sigc::nil, sigc::nil, sigc::nil, sigc::nil, sigc::nil>, void, gmref_ptr<Ekiga::Bank>, gmref_ptr<Ekiga::Account>, Ekiga::Account::RegistrationState, std::string>::call_it(sigc::internal::slot_rep*, gmref_ptr<Ekiga::Bank> const&, gmref_ptr<Ekiga::Account> const&, Ekiga::Account::RegistrationState const&, std::string const&)',
            'Ekiga::AccountCore::on_registration_event(gmref_ptr<Ekiga::Bank>, gmref_ptr<Ekiga::Account>, Ekiga::Account::RegistrationState, std::string)',
            'sigc::internal::slot_call3<sigc::bind_functor<0, sigc::bound_mem_functor4<void, Ekiga::AccountCore, gmref_ptr<Ekiga::Bank>, gmref_ptr<Ekiga::Account>, Ekiga::Account::RegistrationState, std::string>, gmref_ptr<Ekiga::Bank>, sigc::nil, sigc::nil, sigc::nil, sigc::nil, sigc::nil, sigc::nil>, void, gmref_ptr<Ekiga::Account>, Ekiga::Account::RegistrationState, std::string>::call_it(sigc::internal::slot_rep*, gmref_ptr<Ekiga::Account> const&, Ekiga::Account::RegistrationState const&, std::string const&)',
            'Ekiga::BankImpl<Opal::Account>::on_registration_event(Ekiga::Account::RegistrationState, std::string, gmref_ptr<Opal::Account>)',
        ],
    },
    # Contains frames that have been edited to lack parentheses
    'gnome-bug-586192' => {
        threads => 1,
        thread  => Math::BigInt->new('0x7fde5f3f1950'),
        frames  => 12,
        trace_lines => 16,
        thread_array_pos => 0,
        stack => [qw(
            raise
            abort
            ??
            ??
            free
            load_encrypted_key
            parsed_pem_block
            egg_openssl_pem_parse
            gck_ssh_openssh_parse_private_key
            unlock_private_key
            realize_and_take_data
            gck_ssh_private_key_parse
        )],
    },
    # Ends in a frame that has an open-paren with no close-paren.
    'gnome-bug-579416' => {
        threads => 2,
        thread  => 1,
        frames  => 17,
        trace_lines => 105,
        stack => [qw(
            __kernel_vsyscall
            __lll_lock_wait
            _L_lock_752
            __pthread_mutex_lock
            gst_object_get_name
            ??
            PyObject_Repr
            PyString_Format
            string_mod
            binary_op1
            binary_op
            PyEval_EvalFrameEx
            fast_function
            call_function
            PyEval_EvalFrameEx
            PyEval_EvalCodeEx
            PyEval_EvalCode
        )],
    },
    # Contains "operator new" as a function name.
    'gnome-bug-538866' => {
        threads => 10,
        thread  => 3,
        frames  => 15,
        trace_lines => 382,
    },
    # Objective C frames like -[NSView function_name]
    'gnome-bug-578811' => {
        threads => 1,
        thread  => 1,
        frames  => 9,
        trace_lines => 15,
        stack => [
            '-[NSView setFrameSize:]',
            '-[NSView setFrame:]',
            '-[NSWindow setContentView:]',
            '-[GstGLNSWindow initWithContentRect:styleMask:backing:defer:screen:gstWin:]',
            'gst_gl_window_new',
            'gst_gl_display_thread_create_context',
            'g_thread_create_proxy',
            '_pthread_start',
            'thread_start',
        ],
    },
    # Contains a crazy function name: wxvault!??0Cwxvault@@QAE@XZ
    'gnome-bug-565375' => {
        threads => 1,
        thread  => 1,
        frames  => 150,
        trace_lines => 160,
    },
    # Contains a bunch of frames in the default thread, and then nothing
    # in a thread that comes after that.
    'gnome-bug-583460' => {
        threads => 1,
        thread  => 1,
        frames  => 35,
        trace_lines => 35,
    },
    # Contains a thread with an id in hex without 0x in front of it.
    'gnome-bug-589747' => {
        threads => 17,
        thread  => Math::BigInt->new('0x4ae9c280a'),
        thread_array_pos => 0,
        frames  => 17,
        trace_lines => 84,
    },
    # Contains frames without memory locations, including functions
    # that start with _.
    'gnome-bug-585454' => {
        threads => 21,
        thread  => 4,
        frames  => 12,
        trace_lines => 247,
    },
    
};

foreach my $file (sort keys %{ TRACES() }) {
    test_trace('GDB', $file, TRACES->{$file});
}

