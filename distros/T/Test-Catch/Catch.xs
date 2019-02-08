#include <math.h> // this fixes win32 because <cmath> that is included by <catch.hpp> breaks <perl.h> unless previously included <math.h>
#define CATCH_CONFIG_RUNNER
#define CATCH_CONFIG_DEFAULT_REPORTER "perl"
#include <catch.hpp>
#include <vector>
#include <xsheader.h>

using namespace Catch;
using namespace std;

static Catch::Session session;

struct PerlReporter : StreamingReporterBase<PerlReporter> {
    using Super = StreamingReporterBase<PerlReporter>;
    struct Scope {
        uint32_t    count;
        uint32_t    failed;
        uint32_t    depth;
        std::string name;
    };
    static Scope context;
    
    PerlReporter (ReporterConfig const& _config)
        : Super(_config)
    {
        m_reporterPrefs.shouldReportAllAssertions = true;
    }

    static std::string getDescription () {
        return "Reports test results in perl test-harness compatible format";
    }
    
    void testRunStarting (const TestRunInfo& info) override {
        Super::testRunStarting(info);
        scopes.push_back(context);
        scope = &scopes.back();
    }
    
    void testRunEnded (const TestRunStats& stats) override {
        context.count  = scope->count;
        context.failed = scope->failed;
        scopes.clear();
        scope = nullptr;
        Super::testRunEnded(stats);
    }
    
    void sectionStarting (const SectionInfo& info) override {
        Super::sectionStarting(info);
        startLine();
        auto name = scope->name.length() ? (scope->name + " / " + info.name) : info.name;
        stream << "# Subtest: " << name << endl;
        scopes.push_back({0, 0, scope->depth + 1, name});
        scope = &scopes.back();
    }
    
    void sectionEnded (const SectionStats& stats) override {
        auto name = scope->name;
        bool failed = scope->failed;
        startLine() << "1.." << scope->count << endl;
        if (scope->failed) {
            startErrorLine() << "# Looks like you failed " << scope->failed << " test of " << scope->count << " at [" << name << "]." << endl;
        }
        
        scopes.pop_back();
        if (scopes.empty()) throw "WTF?";
        scope = &scopes.back();
        
        ++scope->count;
        startLine();
        if (failed) {
            ++scope->failed;
            stream << "not ok";
        }
        else stream << "ok";
        stream << " " << scope->count << " - [" << name << "]" << endl;

        Super::sectionEnded(stats);
    }
    
    std::ostream& startLine () {
        for (size_t i = 0; i < scope->depth; ++i) stream << "    ";
        return stream;
    }

    std::ostream& startErrorLine () {
        for (size_t i = 0; i < scope->depth; ++i) std::cerr << "    ";
        return std::cerr;
    }

    void noMatchingTestCases (const std::string& spec) override {
        startErrorLine() << "# No test cases matched '" << spec << "'" << endl;
    }

    void assertionStarting (const AssertionInfo&) override {}

    bool assertionEnded (const AssertionStats& stats) override {
        auto result = stats.assertionResult;
        // prevent diagnostic messages from counting
        bool is_test = result.getResultType() != ResultWas::Info && result.getResultType() != ResultWas::Warning;
        
        Colour::Code color = Colour::None;
        startLine();
        if (is_test) {
            ++scope->count;
            if (result.succeeded()) {
                stream << "ok";
            } else {
                ++scope->failed;
                stream << "not ok";
                color = Colour::ResultError;
            }
            stream << " " << scope->count << " -";
        }
        
        {
            Colour cg(color); (void)cg;
            AssertionPrinter(stream, stats).print();
            stream << " # at " << result.getSourceInfo();
        }

        stream << endl;

        if (is_test && !result.succeeded()) {
            startErrorLine() << "#\e[1;31m Failed test in section [" << scope->name << "] at " << result.getSourceInfo() << "\e[0m" << endl;
        }
        
        return true;
    }

private:
    std::vector<Scope> scopes;
    Scope* scope;

    struct AssertionPrinter {
        AssertionPrinter& operator= ( AssertionPrinter const& ) = delete;
        AssertionPrinter( AssertionPrinter const& ) = delete;
        AssertionPrinter( std::ostream& _stream, AssertionStats const& _stats)
        : stream( _stream )
        , result( _stats.assertionResult )
        , messages( _stats.infoMessages )
        , itMessage( _stats.infoMessages.begin() )
        , printInfoMessages( true )
        {}

        void print () {
            itMessage = messages.begin();

            switch (result.getResultType()) {
                case ResultWas::Ok:
                    printOriginalExpression();
                    printReconstructedExpression();
                    printRemainingMessages();
                    break;
                case ResultWas::ExpressionFailed:
                    printOriginalExpression();
                    printReconstructedExpression();
                    if (result.isOk()) printIssue(" # TODO");
                    printRemainingMessages();
                    break;
                case ResultWas::ThrewException:
                    printIssue("unexpected exception ");
                    printExpressionWas();
                    printRemainingMessages();
                    break;
                case ResultWas::FatalErrorCondition:
                    printIssue("fatal error condition with message:");
                    printMessage();
                    printExpressionWas();
                    printRemainingMessages();
                    break;
                case ResultWas::DidntThrowException:
                    printIssue("expected exception, got none");
                    printExpressionWas();
                    printRemainingMessages();
                    break;
                case ResultWas::Info:
                    stream << "#info";
                    printMessage();
                    printRemainingMessages();
                    break;
                case ResultWas::Warning:
                    stream << "#warning";
                    printMessage();
                    printRemainingMessages();
                    break;
                case ResultWas::ExplicitFailure:
                    printIssue("explicitly");
                    printRemainingMessages();
                    break;
                // These cases are here to prevent compiler warnings
                case ResultWas::Unknown:
                case ResultWas::FailureBit:
                case ResultWas::Exception:
                    stream << "** unsupported ResultWas (should not happenned) **";
                    break;
            }
        }

    private:
        void printIssue (const std::string& issue) const {
            stream << " " << issue;
        }

        void printExpressionWas () {
            if (!result.hasExpression()) return;
            stream << "; expression was:";
            printOriginalExpression();
        }

        void printOriginalExpression () const {
            if (result.hasExpression()) stream << " " << result.getExpression();
        }

        void printReconstructedExpression () const {
            if (!result.hasExpandedExpression()) return;
            stream << " for: ";
            std::string expr = result.getExpandedExpression();
            std::replace( expr.begin(), expr.end(), '\n', ' ');
            stream << expr;
        }

        void printMessage () {
            if (itMessage != messages.end()) {
                stream << " '" << itMessage->message << "'";
                ++itMessage;
            }
        }

        void printRemainingMessages () {
            if (itMessage == messages.end()) return;

            // using messages.end() directly (or auto) yields compilation error:
            std::vector<MessageInfo>::const_iterator itEnd = messages.end();
            const std::size_t N = static_cast<std::size_t>(std::distance(itMessage, itEnd));

            stream << " with " << pluralise( N, "message" ) << ":";

            for (; itMessage != itEnd; ++itMessage) {
                // If this assertion is a warning ignore any INFO messages
                if (printInfoMessages || itMessage->type != ResultWas::Info) {
                    stream << "\n#   " << itMessage->message;
                }
            }
        }

    private:
        std::ostream& stream;
        AssertionResult const& result;
        std::vector<MessageInfo> messages;
        std::vector<MessageInfo>::const_iterator itMessage;
        bool printInfoMessages;
        std::size_t counter;
    };
};

PerlReporter::Scope PerlReporter::context;
    
CATCH_REGISTER_REPORTER("perl", PerlReporter);

MODULE = Test::Catch                PACKAGE = Test::Catch
PROTOTYPES: DISABLE

bool _run (SV* count, SV* failed, int depth, ...) {
    int err;
    {
        std::vector<const char*> argv = {"test"};
        
        for (int i = 3; i < items; ++i) {
            SV* arg = ST(i);
            if (!SvOK(arg)) continue;
            argv.push_back(SvPV_nolen(arg));
        }
        
        argv.push_back("-i");
        
        session.useConfigData({});
        err = session.applyCommandLine(argv.size(), argv.data());
    }
    if (err) croak("session.applyCommandLine: error %d", err);
    
    PerlReporter::context.count  = SvUV(count);
    PerlReporter::context.failed = SvUV(failed);
    PerlReporter::context.depth  = depth;
    
    RETVAL = session.run() == 0;
    
    sv_setuv(count, PerlReporter::context.count);
    sv_setuv(failed, PerlReporter::context.failed);
}
