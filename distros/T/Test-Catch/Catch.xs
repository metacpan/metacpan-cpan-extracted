#include <math.h> // this fixes win32 because <cmath> that is included by <catch.hpp> breaks <perl.h> unless previously included <math.h>
#define CATCH_CONFIG_RUNNER
#define CATCH_CONFIG_DEFAULT_REPORTER "perl"
#include <catch2/catch.hpp>
#include <vector>
#include <xsheader.h>

using namespace Catch;
using namespace std;

static Catch::Session session;

struct Printer {
    Printer (ostream& _stream, const AssertionStats& _stats)
        : stream(_stream), result(_stats.assertionResult), messages(_stats.infoMessages), itMessage(_stats.infoMessages.begin()) {}

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
    static inline void expr_replace (string& expr, char c, const string& subs) {
        size_t pos = expr.find(c);
        while (pos < expr.length()) {
            expr.replace(pos, 1, subs);
            pos = expr.find(c, pos + subs.length());
        }
    }
    
    void printIssue (const string& issue) const {
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
        string expr = result.getExpandedExpression();
        expr_replace(expr, '\r', "\\r");
        expr_replace(expr, '\n', "\\n");
        stream << expr;
    }

    void printMessage () {
        if (itMessage != messages.end()) {
            stream << " '" << itMessage->message << "'";
            ++itMessage;
        }
    }

    void printRemainingMessages () {
        if (itMessage == messages.cend()) return;

        // using messages.end() directly (or auto) yields compilation error:
        auto itEnd = messages.cend();
        const size_t N = static_cast<size_t>(std::distance(itMessage, itEnd));

        stream << " with " << pluralise( N, "message" ) << ":";

        for (; itMessage != itEnd; ++itMessage) {
            // If this assertion is a warning ignore any INFO messages
            if (itMessage->type != ResultWas::Info) {
                stream << "\n#   " << itMessage->message;
            }
        }
    }

    ostream& stream;
    AssertionResult const& result;
    vector<MessageInfo> messages;
    vector<MessageInfo>::const_iterator itMessage;
};


struct PerlReporter : IStreamingReporter {
    struct Scope {
        uint32_t count;
        uint32_t failed;
        uint32_t depth;
        string   name;
        string   fullname;
    };
    static Scope context;

    static string getDescription () { return "Reports test results in perl test-harness compatible format"; }
    
    PerlReporter (const ReporterConfig& _config)
        : scope(), sliding_scope(), fatal(), config(_config.fullConfig()), stream(_config.stream())
    {
        reporterPrefs.shouldRedirectStdOut = false;
        reporterPrefs.shouldReportAllAssertions = true;
    }
    
    ReporterPreferences getPreferences () const override { return reporterPrefs; }

    void noMatchingTestCases (const string& spec) override {
        startErrorLine() << "# No test cases matched '" << spec << "'" << endl;
    }
    
    void skipTest (const TestCaseInfo&) override {}
    
    void testRunStarting (const TestRunInfo&) override {
        scopes.push_back(context);
        scope = &scopes.back();
    }
    
    void testRunEnded (const TestRunStats&) override {
        context.count  = scope->count;
        context.failed = scope->failed;
        scopes.clear();
        scope = nullptr;
    }
    
    void testGroupStarting (const GroupInfo&)      override {}
    void testGroupEnded    (const TestGroupStats&) override {}
    
    void testCaseStarting (const TestCaseInfo&)  override {}
    
    void testCaseEnded (const TestCaseStats&) override {
        if (fatal) {
            commitAssertions();
            sliding_scope = &scopes[1];
        }
        commitSlidingScope();
    }
    
    void sectionStarting (const SectionInfo& info) override {
        if (sliding_scope && sliding_scope->name == info.name) {
            ++sliding_scope;
            return;
        }
        commitSlidingScope();
        startScope(info);
    }
    
    void startScope (const SectionInfo& info) {
        startLine();
        auto fullname = scope->fullname.length() ? (scope->fullname + " / " + info.name) : info.name;
        stream << "# Subtest: " << fullname << endl;
        scopes.push_back({0, 0, scope->depth + 1, info.name, fullname});
        scope = &scopes.back();
    }
    
    void sectionEnded (const SectionStats&) override {
        if (fatal) return;
        if (!sliding_scope) sliding_scope = scope + 1;
        --sliding_scope;
        if (sliding_scope == &scopes[1]) commitAssertions();
    }
    
    void commitSlidingScope () {
        if (!sliding_scope) return;
        size_t cnt = &scopes.back() - sliding_scope + 1;
        while (cnt--) closeCurrentScope();
        sliding_scope = nullptr;
    }
    
    void closeCurrentScope () {
        auto name = scope->fullname;
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
    }
    
    ostream& startLine () {
        for (size_t i = 0; i < scope->depth; ++i) stream << "    ";
        return stream;
    }

    ostream& startErrorLine () {
        for (size_t i = 0; i < scope->depth; ++i) std::cerr << "    ";
        return std::cerr;
    }

    void assertionStarting (const AssertionInfo&) override {}

    bool assertionEnded (const AssertionStats& stats) override {
        ostringstream s;
        Printer(s, stats).print();
        assertions.push_back({stats, s.str()});
        return true;
    }
    
    void commitAssertions () {
        for (auto& row : assertions) {
            auto& stats = row.stats;
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
                stream << row.expr;
                stream << " # at " << result.getSourceInfo();
            }
    
            stream << endl;
    
            if (is_test && !result.succeeded()) {
                startErrorLine() << "#\e[1;31m Failed test in section [" << scope->fullname << "] at " << result.getSourceInfo() << "\e[0m" << endl;
            }
        }
        assertions.clear();
    }
    
    void fatalErrorEncountered (StringRef) override {
        fatal = true;
    }

private:
    struct AData {
        AssertionStats stats;
        string         expr;
    };
    
    vector<Scope>       scopes;
    Scope*              scope;
    Scope*              sliding_scope;
    vector<AData>       assertions;
    bool                fatal;
    ReporterPreferences reporterPrefs;
    IConfigPtr          config;
    ostream&            stream;
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
