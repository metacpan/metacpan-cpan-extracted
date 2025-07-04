# This Makefile is for the OpenAPI::Client::OpenAI extension to perl.
#
# It was generated automatically by MakeMaker version
# 7.74 (Revision: 77400) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT_FROM => q[lib/OpenAPI/Client/OpenAI.pm]
#     AUTHOR => [q[Nelson Ferraz <nferraz@gmail.com>]]
#     BUILD_REQUIRES => { ExtUtils::MakeMaker=>q[0], Feature::Compat::Try=>q[0], File::Slurp=>q[0], Markdown::Pod=>q[0], Path::Tiny=>q[0], Perl::Tidy=>q[0], Template=>q[0], Text::Wrap=>q[0], YAML::XS=>q[0] }
#     CONFIGURE_REQUIRES => { ExtUtils::MakeMaker=>q[0], File::ShareDir::Install=>q[0], IO::Socket::SSL=>q[2] }
#     LICENSE => q[artistic_2]
#     META_MERGE => { meta-spec=>{ version=>q[2] }, resources=>{ bugtracker=>{ web=>q[https://github.com/nferraz/perl-openapi-client-openai/issues] }, repository=>{ type=>q[git], url=>q[https://github.com/nferraz/perl-openapi-client-openai.git], web=>q[https://github.com/nferraz/perl-openapi-client-openai] } } }
#     MIN_PERL_VERSION => q[5.014000]
#     NAME => q[OpenAPI::Client::OpenAI]
#     PREREQ_PM => { ExtUtils::MakeMaker=>q[0], Feature::Compat::Try=>q[0], File::ShareDir=>q[0], File::Slurp=>q[0], File::Spec::Functions=>q[0], Import::Base=>q[1.004], JSON=>q[4.10], Markdown::Pod=>q[0], OpenAPI::Client=>q[1.07], Path::Tiny=>q[0], Perl::Tidy=>q[20240511], Template=>q[0], Test::Most=>q[0], Test::RequiresInternet=>q[0], Text::Wrap=>q[0], YAML::XS=>q[0] }
#     TEST_REQUIRES => { Import::Base=>q[1.004], JSON=>q[4.10], Perl::Tidy=>q[20240511], Test::Most=>q[0], Test::RequiresInternet=>q[0] }
#     VERSION_FROM => q[lib/OpenAPI/Client/OpenAI.pm]
#     clean => { FILES=>q[OpenAPI-Client-OpenAI-*] }
#     dist => { COMPRESS=>q[gzip -9f], SUFFIX=>q[gz] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0/darwin-2level/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS =  
CCDLFLAGS =  
CPPRUN = cc  -E
DLEXT = bundle
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS =  -mmacosx-version-min=14.5 -bundle -undefined dynamic_lookup -L/usr/local/lib -L/opt/local/lib -fstack-protector-strong
LDFLAGS =  -mmacosx-version-min=14.5 -fstack-protector-strong -L/usr/local/lib -L/opt/local/lib
LIBC = 
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = darwin
OSVERS = 23.5.0
RANLIB = ranlib
SITELIBEXP = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/site_perl/5.40.0
SITEARCHEXP = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/site_perl/5.40.0/darwin-2level
SO = dylib
VENDORARCHEXP = 
VENDORLIBEXP = 


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = OpenAPI::Client::OpenAI
NAME_SYM = OpenAPI_Client_OpenAI
VERSION = 0.23
VERSION_MACRO = VERSION
VERSION_SYM = 0_23
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.23
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1
MAN3EXT = 3
MAN1SECTION = 1
MAN3SECTION = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0
SITEPREFIX = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0
VENDORPREFIX = 
INSTALLPRIVLIB = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/site_perl/5.40.0
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = 
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0/darwin-2level
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/site_perl/5.40.0/darwin-2level
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = 
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = 
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = 
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = 
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = 
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0
PERL_ARCHLIB = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0/darwin-2level
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0/darwin-2level/CORE
PERL = "/Users/ovid/perl5/perlbrew/perls/perl-5.40.0/bin/perl"
FULLPERL = "/Users/ovid/perl5/perlbrew/perls/perl-5.40.0/bin/perl"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/site_perl/5.40.0/ExtUtils/MakeMaker.pm
MM_VERSION  = 7.74
MM_REVISION = 77400

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = OpenAPI/Client/OpenAI
BASEEXT = OpenAI
PARENT_NAME = OpenAPI::Client
DLBASE = $(BASEEXT)
VERSION_FROM = lib/OpenAPI/Client/OpenAI.pm
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = 
MAN3PODS = lib/OpenAPI/Client/OpenAI.pm \
	lib/OpenAPI/Client/OpenAI/Methods.pod \
	lib/OpenAPI/Client/OpenAI/Path.pod \
	lib/OpenAPI/Client/OpenAI/Path/assistants-assistant_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/assistants.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-speech.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-transcriptions.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-translations.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches-batch_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches-batch_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id-messages.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers.pod \
	lib/OpenAPI/Client/OpenAI/Path/embeddings.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items-output_item_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals.pod \
	lib/OpenAPI/Client/OpenAI/Path/files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/files.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-run.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-validate.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions-permission_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-permission_id-permissions.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-checkpoints.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-events.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-pause.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-resume.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-edits.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-generations.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-variations.pod \
	lib/OpenAPI/Client/OpenAI/Path/models-model.pod \
	lib/OpenAPI/Client/OpenAI/Path/models.pod \
	lib/OpenAPI/Client/OpenAI/Path/moderations.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys-key_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-audit_logs.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-activate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-certificate_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-deactivate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-costs.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-invites-invite_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-invites.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys-key_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-archive.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-activate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-deactivate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits-rate_limit_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts-service_account_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users-user_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_speeches.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_transcriptions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-code_interpreter_sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-embeddings.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-images.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-moderations.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-vector_stores.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-users-user_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-users.pod \
	lib/OpenAPI/Client/OpenAI/Path/realtime-sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/realtime-transcription_sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id-input_items.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages-message_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps-step_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-submit_tool_outputs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-complete.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-parts.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-search.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores.pod

# Where to build things
INST_LIBDIR      = $(INST_LIB)/OpenAPI/Client
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/OpenAPI/Client

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/OpenAPI/Client/OpenAI.pm \
	lib/OpenAPI/Client/OpenAI/Methods.pod \
	lib/OpenAPI/Client/OpenAI/Path.pod \
	lib/OpenAPI/Client/OpenAI/Path/assistants-assistant_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/assistants.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-speech.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-transcriptions.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-translations.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches-batch_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches-batch_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id-messages.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers.pod \
	lib/OpenAPI/Client/OpenAI/Path/embeddings.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items-output_item_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals.pod \
	lib/OpenAPI/Client/OpenAI/Path/files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/files.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-run.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-validate.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions-permission_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-permission_id-permissions.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-checkpoints.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-events.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-pause.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-resume.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-edits.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-generations.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-variations.pod \
	lib/OpenAPI/Client/OpenAI/Path/models-model.pod \
	lib/OpenAPI/Client/OpenAI/Path/models.pod \
	lib/OpenAPI/Client/OpenAI/Path/moderations.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys-key_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-audit_logs.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-activate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-certificate_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-deactivate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-costs.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-invites-invite_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-invites.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys-key_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-archive.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-activate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-deactivate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits-rate_limit_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts-service_account_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users-user_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_speeches.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_transcriptions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-code_interpreter_sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-embeddings.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-images.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-moderations.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-vector_stores.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-users-user_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-users.pod \
	lib/OpenAPI/Client/OpenAI/Path/realtime-sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/realtime-transcription_sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id-input_items.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages-message_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps-step_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-submit_tool_outputs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-complete.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-parts.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-search.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores.pod
PERL_ARCHLIBDEP = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0/darwin-2level
PERL_INCDEP = /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0/darwin-2level/CORE


# Dependencies info
PERL_ARCHIVEDEP    = 

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIBDEP)$(DFSEP)Config.pm $(PERL_INCDEP)$(DFSEP)config.h


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 7.74
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'cp_nonempty' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = COPY_EXTENDED_ATTRIBUTES_DISABLE=1 COPYFILE_DISABLE=1 tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip -9f
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = OpenAPI-Client-OpenAI
DISTVNAME = OpenAPI-Client-OpenAI-0.23


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	PASTHRU_DEFINE='$(DEFINE) $(PASTHRU_DEFINE)'\
	PASTHRU_INC='$(INC) $(PASTHRU_INC)'


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir pure_all subdirs clean_subdirs makemakerdflt manifypods realclean_subdirs subdirs_dynamic subdirs_pure_nolink subdirs_static subdirs-test_dynamic subdirs-test_static test_dynamic test_static



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: dynamic
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) config $(INST_BOOT) $(INST_DYNAMIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all config  \
	lib/OpenAPI/Client/OpenAI.pm \
	lib/OpenAPI/Client/OpenAI/Methods.pod \
	lib/OpenAPI/Client/OpenAI/Path.pod \
	lib/OpenAPI/Client/OpenAI/Path/assistants-assistant_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/assistants.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-speech.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-transcriptions.pod \
	lib/OpenAPI/Client/OpenAI/Path/audio-translations.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches-batch_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches-batch_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/batches.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id-messages.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/chat-completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers-container_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/containers.pod \
	lib/OpenAPI/Client/OpenAI/Path/embeddings.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items-output_item_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals-eval_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/evals.pod \
	lib/OpenAPI/Client/OpenAI/Path/files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/files.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-run.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-validate.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions-permission_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-permission_id-permissions.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-checkpoints.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-events.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-pause.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-resume.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-edits.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-generations.pod \
	lib/OpenAPI/Client/OpenAI/Path/images-variations.pod \
	lib/OpenAPI/Client/OpenAI/Path/models-model.pod \
	lib/OpenAPI/Client/OpenAI/Path/models.pod \
	lib/OpenAPI/Client/OpenAI/Path/moderations.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys-key_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-audit_logs.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-activate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-certificate_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates-deactivate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-certificates.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-costs.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-invites-invite_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-invites.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys-key_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-archive.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-activate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-deactivate.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits-rate_limit_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts-service_account_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users-user_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-projects.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_speeches.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_transcriptions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-code_interpreter_sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-completions.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-embeddings.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-images.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-moderations.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-usage-vector_stores.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-users-user_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/organization-users.pod \
	lib/OpenAPI/Client/OpenAI/Path/realtime-sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/realtime-transcription_sessions.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id-input_items.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses-response_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/responses.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages-message_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps-step_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-submit_tool_outputs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads-thread_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/threads.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-complete.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-parts.pod \
	lib/OpenAPI/Client/OpenAI/Path/uploads.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-cancel.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id-content.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-search.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id.pod \
	lib/OpenAPI/Client/OpenAI/Path/vector_stores.pod
	$(NOECHO) $(POD2MAN) --section=$(MAN3SECTION) --perm_rw=$(PERM_RW) -u \
	  lib/OpenAPI/Client/OpenAI.pm $(INST_MAN3DIR)/OpenAPI::Client::OpenAI.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Methods.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Methods.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/assistants-assistant_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::assistants-assistant_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/assistants.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::assistants.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/audio-speech.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::audio-speech.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/audio-transcriptions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::audio-transcriptions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/audio-translations.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::audio-translations.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/batches-batch_id-cancel.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::batches-batch_id-cancel.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/batches-batch_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::batches-batch_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/batches.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::batches.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id-messages.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::chat-completions-completion_id-messages.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::chat-completions-completion_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/chat-completions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::chat-completions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/completions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::completions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id-content.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::containers-container_id-files-file_id-content.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::containers-container_id-files-file_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::containers-container_id-files.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/containers-container_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::containers-container_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/containers.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::containers.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/embeddings.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::embeddings.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items-output_item_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::evals-eval_id-runs-run_id-output_items-output_item_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::evals-eval_id-runs-run_id-output_items.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::evals-eval_id-runs-run_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::evals-eval_id-runs.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/evals-eval_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::evals-eval_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/evals.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::evals.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/files-file_id-content.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::files-file_id-content.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/files-file_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::files-file_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/files.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::files.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-run.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-alpha-graders-run.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-validate.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-alpha-graders-validate.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions-permission_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions-permission_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-permission_id-permissions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-checkpoints-permission_id-permissions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-cancel.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-jobs-fine_tuning_job_id-cancel.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-checkpoints.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-jobs-fine_tuning_job_id-checkpoints.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-events.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-jobs-fine_tuning_job_id-events.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-pause.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-jobs-fine_tuning_job_id-pause.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-resume.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-jobs-fine_tuning_job_id-resume.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-jobs-fine_tuning_job_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::fine_tuning-jobs.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/images-edits.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::images-edits.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/images-generations.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::images-generations.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/images-variations.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::images-variations.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/models-model.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::models-model.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/models.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::models.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/moderations.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::moderations.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys-key_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-admin_api_keys-key_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-admin_api_keys.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-audit_logs.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-audit_logs.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-certificates-activate.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-certificates-activate.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-certificates-certificate_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-certificates-certificate_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-certificates-deactivate.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-certificates-deactivate.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-certificates.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-certificates.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-costs.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-costs.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-invites-invite_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-invites-invite_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-invites.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-invites.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys-key_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-api_keys-key_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-api_keys.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-archive.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-archive.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-activate.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-certificates-activate.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-deactivate.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-certificates-deactivate.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-certificates.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits-rate_limit_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-rate_limits-rate_limit_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-rate_limits.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts-service_account_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-service_accounts-service_account_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-service_accounts.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users-user_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-users-user_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id-users.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects-project_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-projects.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-projects.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_speeches.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-usage-audio_speeches.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_transcriptions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-usage-audio_transcriptions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-usage-code_interpreter_sessions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-usage-code_interpreter_sessions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-usage-completions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-usage-completions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-usage-embeddings.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-usage-embeddings.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-usage-images.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-usage-images.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-usage-moderations.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-usage-moderations.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-usage-vector_stores.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-usage-vector_stores.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-users-user_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-users-user_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/organization-users.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::organization-users.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/realtime-sessions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::realtime-sessions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/realtime-transcription_sessions.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::realtime-transcription_sessions.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/responses-response_id-cancel.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::responses-response_id-cancel.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/responses-response_id-input_items.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::responses-response_id-input_items.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/responses-response_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::responses-response_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/responses.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::responses.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-runs.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-runs.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages-message_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id-messages-message_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id-messages.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-cancel.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id-runs-run_id-cancel.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps-step_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id-runs-run_id-steps-step_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id-runs-run_id-steps.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-submit_tool_outputs.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id-runs-run_id-submit_tool_outputs.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id-runs-run_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id-runs.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads-thread_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads-thread_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/threads.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::threads.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-cancel.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::uploads-upload_id-cancel.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-complete.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::uploads-upload_id-complete.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-parts.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::uploads-upload_id-parts.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/uploads.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::uploads.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-cancel.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id-file_batches-batch_id-cancel.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-files.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id-file_batches-batch_id-files.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id-file_batches-batch_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id-file_batches.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id-content.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id-files-file_id-content.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id-files-file_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id-files.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-search.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id-search.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores-vector_store_id.$(MAN3EXT) \
	  lib/OpenAPI/Client/OpenAI/Path/vector_stores.pod $(INST_MAN3DIR)/OpenAPI::Client::OpenAI::Path::vector_stores.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  $(BASEEXT).bso $(BASEEXT).def \
	  $(BASEEXT).exp $(BASEEXT).x \
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)/extralibs.all \
	  $(INST_ARCHAUTODIR)/extralibs.ld $(MAKE_APERL_FILE) \
	  *$(LIB_EXT) *$(OBJ_EXT) \
	  *perl.core MYMETA.json \
	  MYMETA.yml blibdirs.ts \
	  core core.*perl.*.? \
	  core.[0-9] core.[0-9][0-9] \
	  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9][0-9][0-9] lib$(BASEEXT).def \
	  mon.out perl \
	  perl$(EXE_EXT) perl.exe \
	  perlmain.c pm_to_blib \
	  pm_to_blib.ts so_locations \
	  tmon.out 
	- $(RM_RF) \
	  OpenAPI-Client-OpenAI-* blib 
	  $(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
# so clean is forced to complete before realclean_subdirs runs
realclean_subdirs : clean
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge :: realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) 
	- $(RM_RF) \
	  $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) '---' > META_new.yml
	$(NOECHO) $(ECHO) 'abstract: '\''A client for the OpenAI API'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Nelson Ferraz <nferraz@gmail.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Feature::Compat::Try: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Slurp: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Import::Base: '\''1.004'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  JSON: '\''4.10'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Markdown::Pod: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Path::Tiny: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Perl::Tidy: '\''20240511'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Template: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Most: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::RequiresInternet: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Text::Wrap: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  YAML::XS: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::ShareDir::Install: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  IO::Socket::SSL: '\''2'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'dynamic_config: 1' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by: '\''ExtUtils::MakeMaker version 7.74, CPAN::Meta::Converter version 2.150010'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'license: artistic_2' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '  url: http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '  version: '\''1.4'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'name: OpenAPI-Client-OpenAI' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '  directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - t' >> META_new.yml
	$(NOECHO) $(ECHO) '    - inc' >> META_new.yml
	$(NOECHO) $(ECHO) 'requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::ShareDir: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Spec::Functions: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  OpenAPI::Client: '\''1.07'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  perl: '\''5.014000'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'resources:' >> META_new.yml
	$(NOECHO) $(ECHO) '  bugtracker: https://github.com/nferraz/perl-openapi-client-openai/issues' >> META_new.yml
	$(NOECHO) $(ECHO) '  repository: https://github.com/nferraz/perl-openapi-client-openai.git' >> META_new.yml
	$(NOECHO) $(ECHO) 'version: '\''0.23'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'x_serialization_backend: '\''CPAN::Meta::YAML version 0.018'\''' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) '{' > META_new.json
	$(NOECHO) $(ECHO) '   "abstract" : "A client for the OpenAI API",' >> META_new.json
	$(NOECHO) $(ECHO) '   "author" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "Nelson Ferraz <nferraz@gmail.com>"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "dynamic_config" : 1,' >> META_new.json
	$(NOECHO) $(ECHO) '   "generated_by" : "ExtUtils::MakeMaker version 7.74, CPAN::Meta::Converter version 2.150010",' >> META_new.json
	$(NOECHO) $(ECHO) '   "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "artistic_2"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "meta-spec" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' >> META_new.json
	$(NOECHO) $(ECHO) '      "version" : 2' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "name" : "OpenAPI-Client-OpenAI",' >> META_new.json
	$(NOECHO) $(ECHO) '   "no_index" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "directory" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "t",' >> META_new.json
	$(NOECHO) $(ECHO) '         "inc"' >> META_new.json
	$(NOECHO) $(ECHO) '      ]' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "prereqs" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "build" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Feature::Compat::Try" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Slurp" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Markdown::Pod" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Path::Tiny" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Perl::Tidy" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Template" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Text::Wrap" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "YAML::XS" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "configure" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::ShareDir::Install" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "IO::Socket::SSL" : "2"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "runtime" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::ShareDir" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Spec::Functions" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "OpenAPI::Client" : "1.07",' >> META_new.json
	$(NOECHO) $(ECHO) '            "perl" : "5.014000"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "test" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Import::Base" : "1.004",' >> META_new.json
	$(NOECHO) $(ECHO) '            "JSON" : "4.10",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Perl::Tidy" : "20240511",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Most" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::RequiresInternet" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "release_status" : "stable",' >> META_new.json
	$(NOECHO) $(ECHO) '   "resources" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "bugtracker" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "web" : "https://github.com/nferraz/perl-openapi-client-openai/issues"' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "repository" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "type" : "git",' >> META_new.json
	$(NOECHO) $(ECHO) '         "url" : "https://github.com/nferraz/perl-openapi-client-openai.git",' >> META_new.json
	$(NOECHO) $(ECHO) '         "web" : "https://github.com/nferraz/perl-openapi-client-openai"' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "version" : "0.23",' >> META_new.json
	$(NOECHO) $(ECHO) '   "x_serialization_backend" : "JSON::PP version 4.16"' >> META_new.json
	$(NOECHO) $(ECHO) '}' >> META_new.json
	-$(NOECHO) $(MV) META_new.json $(DISTVNAME)/META.json


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)_uu'

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)'
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).zip'
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).shar'
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir distmeta 
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:
ci :
	$(ABSPERLRUN) -MExtUtils::Manifest=maniread -e '@all = sort keys %{ maniread() };' \
	  -e 'print(qq{Executing $(CI) @all\n});' \
	  -e 'system(qq{$(CI) @all}) == 0 or die $$!;' \
	  -e 'print(qq{Executing $(RCS_LABEL) ...\n});' \
	  -e 'system(qq{$(RCS_LABEL) @all}) == 0 or die $$!;' --


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.yml to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.json to MANIFEST: $${'\''@'\''}"' --



# --- MakeMaker distsignature section:
distsignature : distmeta
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLPRIVLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLARCHLIB)" \
		"$(INST_BIN)" "$(DESTINSTALLBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(SITEARCHEXP)/auto/$(FULLEXT)"


pure_site_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLSITELIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLSITEARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLSITEBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSITESCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLSITEMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLSITEMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(PERL_ARCHLIB)/auto/$(FULLEXT)"

pure_vendor_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read "$(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLVENDORLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLVENDORARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLVENDORBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLVENDORSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLVENDORMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLVENDORMAN3DIR)"


doc_perl_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"

doc_vendor_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLARCHLIB)/perllocal.pod"
	-$(NOECHO) $(MKPATH) "$(DESTINSTALLARCHLIB)"
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLARCHLIB)/perllocal.pod"


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) "$(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist"

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist"

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) "$(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist"


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = "/Users/ovid/perl5/perlbrew/perls/perl-5.40.0/bin/perl"
MAP_PERLINC   = "-Iblib/arch" "-Iblib/lib" "-I/Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0/darwin-2level" "-I/Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/5.40.0"

$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : static $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR="" \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:
TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)
	$(NOECHO) $(NOOP)

test :: $(TEST_TYPE)
	$(NOECHO) $(NOOP)

# Occasionally we may face this degenerate target:
test_ : test_dynamic
	$(NOECHO) $(NOOP)

subdirs-test_dynamic :: dynamic pure_all

test_dynamic :: subdirs-test_dynamic
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: dynamic pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

subdirs-test_static :: static pure_all

test_static :: subdirs-test_static
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_static :: static pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="OpenAPI-Client-OpenAI" VERSION="0.23">' > OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>A client for the OpenAI API</ABSTRACT>' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Nelson Ferraz &lt;nferraz@gmail.com&gt;</AUTHOR>' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '        <PERLCORE VERSION="5,014000,0,0" />' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::ShareDir" />' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Spec::Functions" />' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="OpenAPI::Client" VERSION="1.07" />' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="darwin-2level-5.40" />' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> OpenAPI-Client-OpenAI.ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> OpenAPI-Client-OpenAI.ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e '$$i=0; $$n=$$#ARGV; $$i++ until $$i > $$n or $$ARGV[$$i] eq q{--};' \
	  -e 'die q{Failed to find -- in }.join(q{|},@ARGV) if $$i > $$n;' \
	  -e '@parts=splice @ARGV,0,$$i+1;' \
	  -e 'pop @parts; $$filter=join q{ }, map qq{"$$_"}, @parts;' \
	  -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', $$filter, '\''$(PERM_DIR)'\'')' -- $(PM_FILTER) -- \
	  'lib/OpenAPI/Client/OpenAI.pm' 'blib/lib/OpenAPI/Client/OpenAI.pm' \
	  'lib/OpenAPI/Client/OpenAI/Methods.pod' 'blib/lib/OpenAPI/Client/OpenAI/Methods.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/assistants-assistant_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/assistants-assistant_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/assistants.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/assistants.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/audio-speech.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/audio-speech.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/audio-transcriptions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/audio-transcriptions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/audio-translations.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/audio-translations.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/batches-batch_id-cancel.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/batches-batch_id-cancel.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/batches-batch_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/batches-batch_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/batches.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/batches.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id-messages.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id-messages.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/chat-completions-completion_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/chat-completions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/chat-completions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/completions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/completions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id-content.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id-content.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files-file_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/containers-container_id-files.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/containers-container_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/containers-container_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/containers.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/containers.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/embeddings.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/embeddings.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items-output_item_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items-output_item_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id-output_items.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs-run_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/evals-eval_id-runs.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/evals-eval_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/evals-eval_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/evals.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/evals.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/files-file_id-content.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/files-file_id-content.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/files-file_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/files-file_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/files.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/files.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-run.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-run.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-validate.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-alpha-graders-validate.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions-permission_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions-permission_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-fine_tuned_model_checkpoint-permissions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-permission_id-permissions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-checkpoints-permission_id-permissions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-cancel.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-cancel.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-checkpoints.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-checkpoints.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-events.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-events.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-pause.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-pause.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-resume.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id-resume.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs-fine_tuning_job_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/fine_tuning-jobs.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/images-edits.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/images-edits.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/images-generations.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/images-generations.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/images-variations.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/images-variations.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/models-model.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/models-model.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/models.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/models.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/moderations.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/moderations.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys-key_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys-key_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-admin_api_keys.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-audit_logs.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-audit_logs.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-certificates-activate.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-certificates-activate.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-certificates-certificate_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-certificates-certificate_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-certificates-deactivate.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-certificates-deactivate.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-certificates.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-certificates.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-costs.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-costs.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-invites-invite_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-invites-invite_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-invites.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-invites.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys-key_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys-key_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-api_keys.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-archive.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-archive.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-activate.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-activate.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-deactivate.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates-deactivate.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-certificates.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits-rate_limit_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits-rate_limit_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-rate_limits.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts-service_account_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts-service_account_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-service_accounts.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users-user_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users-user_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id-users.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects-project_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-projects.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-projects.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_speeches.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_speeches.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_transcriptions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-usage-audio_transcriptions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-usage-code_interpreter_sessions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-usage-code_interpreter_sessions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-usage-completions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-usage-completions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-usage-embeddings.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-usage-embeddings.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-usage-images.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-usage-images.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-usage-moderations.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-usage-moderations.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-usage-vector_stores.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-usage-vector_stores.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-users-user_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-users-user_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/organization-users.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/organization-users.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/realtime-sessions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/realtime-sessions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/realtime-transcription_sessions.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/realtime-transcription_sessions.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/responses-response_id-cancel.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/responses-response_id-cancel.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/responses-response_id-input_items.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/responses-response_id-input_items.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/responses-response_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/responses-response_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/responses.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/responses.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-runs.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-runs.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages-message_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages-message_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-messages.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-cancel.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-cancel.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps-step_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps-step_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-steps.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-submit_tool_outputs.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id-submit_tool_outputs.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs-run_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id-runs.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads-thread_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads-thread_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/threads.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/threads.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-cancel.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-cancel.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-complete.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-complete.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-parts.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/uploads-upload_id-parts.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/uploads.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/uploads.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-cancel.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-cancel.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-files.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id-files.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches-batch_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-file_batches.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id-content.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id-content.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files-file_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-files.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-search.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id-search.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores-vector_store_id.pod' \
	  'lib/OpenAPI/Client/OpenAI/Path/vector_stores.pod' 'blib/lib/OpenAPI/Client/OpenAI/Path/vector_stores.pod' 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:

# here so even if top_targets is overridden, these will still be defined
# gmake will silently still work if any are .PHONY-ed but nmake won't

test_static ::
	$(NOECHO) $(NOOP)

test_dynamic ::
	$(NOECHO) $(NOOP)

static ::
	$(NOECHO) $(NOOP)

dynamic ::
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)


# --- MakeMaker postamble section:
config::
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/openapi.yaml' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/openapi.yaml' 


# End.
