use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Quiq',
    VERSION_FROM => 'lib/Quiq.pm',
    MIN_PERL_VERSION => 5.16.0,
    BUILD_REQUIRES => {
        ExtUtils::MakeMaker => 6.48, # wg. MIN_PERL_VERSION
    },
    PREREQ_PM => {
        Data::Printer => 0,
        DB_File => 0,
        DBD::SQLite => 0,
        DBI => 0,
        Excel::Writer::XLSX => 0,
        File::Rsync => 0.49,
        HTTP::Request => 0,
        Image::Size => 0,
        JSON => 0,
        LWP::UserAgent => 0,
        Mojolicious::Plugin => 0,
        Net::SSH::Perl => 0,
        Pod::WSDL => 0,
        SOAP::Transport::HTTP => 0,
        WWW::Mechanize => 0,
        XML::LibXML => 0,
        XML::Twig => 0,
    },
    ABSTRACT_FROM => 'lib/Quiq.pm',
    AUTHOR => 'Frank Seitz <fs@fseitz.de>',
    LICENSE => 'perl_5',
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2,
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/s31tz/Quiq.git',
                web  => 'https://github.com/s31tz/Quiq',
            },
        },
    },
    META_ADD => {
        provides => {
            Quiq => {
                file => 'lib/Quiq.pm',
                version => '1.148',
            },
            Quiq::AnsiColor => {
                file => 'lib/Quiq/AnsiColor.pm',
                version => '1.148',
            },
            Quiq::ApplicationPaths => {
                file => 'lib/Quiq/ApplicationPaths.pm',
                version => '1.148',
            },
            Quiq::Array => {
                file => 'lib/Quiq/Array.pm',
                version => '1.148',
            },
            Quiq::AsciiTable => {
                file => 'lib/Quiq/AsciiTable.pm',
                version => '1.148',
            },
            Quiq::Assert => {
                file => 'lib/Quiq/Assert.pm',
                version => '1.148',
            },
            Quiq::Cascm => {
                file => 'lib/Quiq/Cascm.pm',
                version => '1.148',
            },
            Quiq::ClassConfig => {
                file => 'lib/Quiq/ClassConfig.pm',
                version => '1.148',
            },
            Quiq::ClassLoader => {
                file => 'lib/Quiq/ClassLoader.pm',
                version => '1.148',
            },
            Quiq::Color => {
                file => 'lib/Quiq/Color.pm',
                version => '1.148',
            },
            Quiq::CommandLine => {
                file => 'lib/Quiq/CommandLine.pm',
                version => '1.148',
            },
            Quiq::Concat => {
                file => 'lib/Quiq/Concat.pm',
                version => '1.148',
            },
            Quiq::Config => {
                file => 'lib/Quiq/Config.pm',
                version => '1.148',
            },
            Quiq::Confluence::Client => {
                file => 'lib/Quiq/Confluence/Client.pm',
                version => '1.148',
            },
            Quiq::Confluence::Markup => {
                file => 'lib/Quiq/Confluence/Markup.pm',
                version => '1.148',
            },
            Quiq::Confluence::Page => {
                file => 'lib/Quiq/Confluence/Page.pm',
                version => '1.148',
            },
            Quiq::ContentProcessor => {
                file => 'lib/Quiq/ContentProcessor.pm',
                version => '1.148',
            },
            Quiq::ContentProcessor::BaseType => {
                file => 'lib/Quiq/ContentProcessor/BaseType.pm',
                version => '1.148',
            },
            Quiq::ContentProcessor::File => {
                file => 'lib/Quiq/ContentProcessor/File.pm',
                version => '1.148',
            },
            Quiq::ContentProcessor::SubType => {
                file => 'lib/Quiq/ContentProcessor/SubType.pm',
                version => '1.148',
            },
            Quiq::ContentProcessor::Type => {
                file => 'lib/Quiq/ContentProcessor/Type.pm',
                version => '1.148',
            },
            Quiq::Converter => {
                file => 'lib/Quiq/Converter.pm',
                version => '1.148',
            },
            Quiq::Css => {
                file => 'lib/Quiq/Css.pm',
                version => '1.148',
            },
            Quiq::Database::Api => {
                file => 'lib/Quiq/Database/Api.pm',
                version => '1.148',
            },
            Quiq::Database::Api::Dbi::Connection => {
                file => 'lib/Quiq/Database/Api/Dbi/Connection.pm',
                version => '1.148',
            },
            Quiq::Database::Api::Dbi::Cursor => {
                file => 'lib/Quiq/Database/Api/Dbi/Cursor.pm',
                version => '1.148',
            },
            Quiq::Database::Connection => {
                file => 'lib/Quiq/Database/Connection.pm',
                version => '1.148',
            },
            Quiq::Database::Cursor => {
                file => 'lib/Quiq/Database/Cursor.pm',
                version => '1.148',
            },
            Quiq::Database::DataAnalysis => {
                file => 'lib/Quiq/Database/DataAnalysis.pm',
                version => '1.148',
            },
            Quiq::Database::ResultSet => {
                file => 'lib/Quiq/Database/ResultSet.pm',
                version => '1.148',
            },
            Quiq::Database::ResultSet::Array => {
                file => 'lib/Quiq/Database/ResultSet/Array.pm',
                version => '1.148',
            },
            Quiq::Database::ResultSet::Object => {
                file => 'lib/Quiq/Database/ResultSet/Object.pm',
                version => '1.148',
            },
            Quiq::Database::Row => {
                file => 'lib/Quiq/Database/Row.pm',
                version => '1.148',
            },
            Quiq::Database::Row::Array => {
                file => 'lib/Quiq/Database/Row/Array.pm',
                version => '1.148',
            },
            Quiq::Database::Row::Object => {
                file => 'lib/Quiq/Database/Row/Object.pm',
                version => '1.148',
            },
            Quiq::Database::Row::Object::Join => {
                file => 'lib/Quiq/Database/Row/Object/Join.pm',
                version => '1.148',
            },
            Quiq::Database::Row::Object::Table => {
                file => 'lib/Quiq/Database/Row/Object/Table.pm',
                version => '1.148',
            },
            Quiq::Database::Tree => {
                file => 'lib/Quiq/Database/Tree.pm',
                version => '1.148',
            },
            Quiq::Debug => {
                file => 'lib/Quiq/Debug.pm',
                version => '1.148',
            },
            Quiq::DestinationTree => {
                file => 'lib/Quiq/DestinationTree.pm',
                version => '1.148',
            },
            Quiq::Digest => {
                file => 'lib/Quiq/Digest.pm',
                version => '1.148',
            },
            Quiq::DirHandle => {
                file => 'lib/Quiq/DirHandle.pm',
                version => '1.148',
            },
            Quiq::Duration => {
                file => 'lib/Quiq/Duration.pm',
                version => '1.148',
            },
            Quiq::Epoch => {
                file => 'lib/Quiq/Epoch.pm',
                version => '1.148',
            },
            Quiq::ExampleCode => {
                file => 'lib/Quiq/ExampleCode.pm',
                version => '1.148',
            },
            Quiq::Excel::Writer => {
                file => 'lib/Quiq/Excel/Writer.pm',
                version => '1.148',
            },
            Quiq::FFmpeg => {
                file => 'lib/Quiq/FFmpeg.pm',
                version => '1.148',
            },
            Quiq::File::Audio => {
                file => 'lib/Quiq/File/Audio.pm',
                version => '1.148',
            },
            Quiq::File::Image => {
                file => 'lib/Quiq/File/Image.pm',
                version => '1.148',
            },
            Quiq::File::Video => {
                file => 'lib/Quiq/File/Video.pm',
                version => '1.148',
            },
            Quiq::FileHandle => {
                file => 'lib/Quiq/FileHandle.pm',
                version => '1.148',
            },
            Quiq::Formatter => {
                file => 'lib/Quiq/Formatter.pm',
                version => '1.148',
            },
            Quiq::Gnuplot::Arrow => {
                file => 'lib/Quiq/Gnuplot/Arrow.pm',
                version => '1.148',
            },
            Quiq::Gnuplot::Graph => {
                file => 'lib/Quiq/Gnuplot/Graph.pm',
                version => '1.148',
            },
            Quiq::Gnuplot::Label => {
                file => 'lib/Quiq/Gnuplot/Label.pm',
                version => '1.148',
            },
            Quiq::Gnuplot::Plot => {
                file => 'lib/Quiq/Gnuplot/Plot.pm',
                version => '1.148',
            },
            Quiq::Gnuplot::Process => {
                file => 'lib/Quiq/Gnuplot/Process.pm',
                version => '1.148',
            },
            Quiq::Hash => {
                file => 'lib/Quiq/Hash.pm',
                version => '1.148',
            },
            Quiq::Html::Base => {
                file => 'lib/Quiq/Html/Base.pm',
                version => '1.148',
            },
            Quiq::Html::Form::Layout => {
                file => 'lib/Quiq/Html/Form/Layout.pm',
                version => '1.148',
            },
            Quiq::Html::Fragment => {
                file => 'lib/Quiq/Html/Fragment.pm',
                version => '1.148',
            },
            Quiq::Html::Image => {
                file => 'lib/Quiq/Html/Image.pm',
                version => '1.148',
            },
            Quiq::Html::List => {
                file => 'lib/Quiq/Html/List.pm',
                version => '1.148',
            },
            Quiq::Html::Listing => {
                file => 'lib/Quiq/Html/Listing.pm',
                version => '1.148',
            },
            Quiq::Html::Page => {
                file => 'lib/Quiq/Html/Page.pm',
                version => '1.148',
            },
            Quiq::Html::Pygments => {
                file => 'lib/Quiq/Html/Pygments.pm',
                version => '1.148',
            },
            Quiq::Html::Table::Base => {
                file => 'lib/Quiq/Html/Table/Base.pm',
                version => '1.148',
            },
            Quiq::Html::Table::List => {
                file => 'lib/Quiq/Html/Table/List.pm',
                version => '1.148',
            },
            Quiq::Html::Table::Simple => {
                file => 'lib/Quiq/Html/Table/Simple.pm',
                version => '1.148',
            },
            Quiq::Html::Tag => {
                file => 'lib/Quiq/Html/Tag.pm',
                version => '1.148',
            },
            Quiq::Html::Util => {
                file => 'lib/Quiq/Html/Util.pm',
                version => '1.148',
            },
            Quiq::Html::Verbatim => {
                file => 'lib/Quiq/Html/Verbatim.pm',
                version => '1.148',
            },
            Quiq::Html::Widget => {
                file => 'lib/Quiq/Html/Widget.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::Button => {
                file => 'lib/Quiq/Html/Widget/Button.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::CheckBox => {
                file => 'lib/Quiq/Html/Widget/CheckBox.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::CheckBoxBar => {
                file => 'lib/Quiq/Html/Widget/CheckBoxBar.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::FileUpload => {
                file => 'lib/Quiq/Html/Widget/FileUpload.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::Hidden => {
                file => 'lib/Quiq/Html/Widget/Hidden.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::RadioButton => {
                file => 'lib/Quiq/Html/Widget/RadioButton.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::RadioButtonBar => {
                file => 'lib/Quiq/Html/Widget/RadioButtonBar.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::ReadOnly => {
                file => 'lib/Quiq/Html/Widget/ReadOnly.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::SelectMenu => {
                file => 'lib/Quiq/Html/Widget/SelectMenu.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::SelectMenuColor => {
                file => 'lib/Quiq/Html/Widget/SelectMenuColor.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::TextArea => {
                file => 'lib/Quiq/Html/Widget/TextArea.pm',
                version => '1.148',
            },
            Quiq::Html::Widget::TextField => {
                file => 'lib/Quiq/Html/Widget/TextField.pm',
                version => '1.148',
            },
            Quiq::Http::Client => {
                file => 'lib/Quiq/Http/Client.pm',
                version => '1.148',
            },
            Quiq::Http::Client::Lwp => {
                file => 'lib/Quiq/Http/Client/Lwp.pm',
                version => '1.148',
            },
            Quiq::Http::Cookie => {
                file => 'lib/Quiq/Http/Cookie.pm',
                version => '1.148',
            },
            Quiq::Http::Message => {
                file => 'lib/Quiq/Http/Message.pm',
                version => '1.148',
            },
            Quiq::Image => {
                file => 'lib/Quiq/Image.pm',
                version => '1.148',
            },
            Quiq::ImageMagick => {
                file => 'lib/Quiq/ImageMagick.pm',
                version => '1.148',
            },
            Quiq::ImagePool => {
                file => 'lib/Quiq/ImagePool.pm',
                version => '1.148',
            },
            Quiq::ImagePool::Directory => {
                file => 'lib/Quiq/ImagePool/Directory.pm',
                version => '1.148',
            },
            Quiq::ImagePool::Sequence => {
                file => 'lib/Quiq/ImagePool/Sequence.pm',
                version => '1.148',
            },
            Quiq::Ipc => {
                file => 'lib/Quiq/Ipc.pm',
                version => '1.148',
            },
            Quiq::JQuery::Accordion => {
                file => 'lib/Quiq/JQuery/Accordion.pm',
                version => '1.148',
            },
            Quiq::JQuery::DataTable => {
                file => 'lib/Quiq/JQuery/DataTable.pm',
                version => '1.148',
            },
            Quiq::JQuery::Form::ViewEdit => {
                file => 'lib/Quiq/JQuery/Form/ViewEdit.pm',
                version => '1.148',
            },
            Quiq::JQuery::Function => {
                file => 'lib/Quiq/JQuery/Function.pm',
                version => '1.148',
            },
            Quiq::JQuery::Tabs => {
                file => 'lib/Quiq/JQuery/Tabs.pm',
                version => '1.148',
            },
            Quiq::JavaScript => {
                file => 'lib/Quiq/JavaScript.pm',
                version => '1.148',
            },
            Quiq::LaTeX::Code => {
                file => 'lib/Quiq/LaTeX/Code.pm',
                version => '1.148',
            },
            Quiq::LaTeX::Document => {
                file => 'lib/Quiq/LaTeX/Document.pm',
                version => '1.148',
            },
            Quiq::LaTeX::Figure => {
                file => 'lib/Quiq/LaTeX/Figure.pm',
                version => '1.148',
            },
            Quiq::LaTeX::LongTable => {
                file => 'lib/Quiq/LaTeX/LongTable.pm',
                version => '1.148',
            },
            Quiq::LineProcessor => {
                file => 'lib/Quiq/LineProcessor.pm',
                version => '1.148',
            },
            Quiq::LineProcessor::Line => {
                file => 'lib/Quiq/LineProcessor/Line.pm',
                version => '1.148',
            },
            Quiq::LockedCounter => {
                file => 'lib/Quiq/LockedCounter.pm',
                version => '1.148',
            },
            Quiq::Math => {
                file => 'lib/Quiq/Math.pm',
                version => '1.148',
            },
            Quiq::MediaWiki::Client => {
                file => 'lib/Quiq/MediaWiki/Client.pm',
                version => '1.148',
            },
            Quiq::MediaWiki::Markup => {
                file => 'lib/Quiq/MediaWiki/Markup.pm',
                version => '1.148',
            },
            Quiq::ModelCache => {
                file => 'lib/Quiq/ModelCache.pm',
                version => '1.148',
            },
            Quiq::Mojolicious::Plugin::Log::Parameters => {
                file => 'lib/Quiq/Mojolicious/Plugin/Log/Parameters.pm',
                version => '1.148',
            },
            Quiq::Object => {
                file => 'lib/Quiq/Object.pm',
                version => '1.148',
            },
            Quiq::Option => {
                file => 'lib/Quiq/Option.pm',
                version => '1.148',
            },
            Quiq::OrderedHash => {
                file => 'lib/Quiq/OrderedHash.pm',
                version => '1.148',
            },
            Quiq::Parallel => {
                file => 'lib/Quiq/Parallel.pm',
                version => '1.148',
            },
            Quiq::Parameters => {
                file => 'lib/Quiq/Parameters.pm',
                version => '1.148',
            },
            Quiq::Path => {
                file => 'lib/Quiq/Path.pm',
                version => '1.148',
            },
            Quiq::Perl => {
                file => 'lib/Quiq/Perl.pm',
                version => '1.148',
            },
            Quiq::PersistentHash => {
                file => 'lib/Quiq/PersistentHash.pm',
                version => '1.148',
            },
            Quiq::Pod::Generator => {
                file => 'lib/Quiq/Pod/Generator.pm',
                version => '1.148',
            },
            Quiq::Process => {
                file => 'lib/Quiq/Process.pm',
                version => '1.148',
            },
            Quiq::Program => {
                file => 'lib/Quiq/Program.pm',
                version => '1.148',
            },
            Quiq::Progress => {
                file => 'lib/Quiq/Progress.pm',
                version => '1.148',
            },
            Quiq::Properties => {
                file => 'lib/Quiq/Properties.pm',
                version => '1.148',
            },
            Quiq::Record => {
                file => 'lib/Quiq/Record.pm',
                version => '1.148',
            },
            Quiq::Reference => {
                file => 'lib/Quiq/Reference.pm',
                version => '1.148',
            },
            Quiq::Rsync => {
                file => 'lib/Quiq/Rsync.pm',
                version => '1.148',
            },
            Quiq::Section::Object => {
                file => 'lib/Quiq/Section/Object.pm',
                version => '1.148',
            },
            Quiq::Section::Parser => {
                file => 'lib/Quiq/Section/Parser.pm',
                version => '1.148',
            },
            Quiq::Shell => {
                file => 'lib/Quiq/Shell.pm',
                version => '1.148',
            },
            Quiq::SoapWsdlServiceCgi => {
                file => 'lib/Quiq/SoapWsdlServiceCgi.pm',
                version => '1.148',
            },
            Quiq::SoapWsdlServiceCgi::Demo => {
                file => 'lib/Quiq/SoapWsdlServiceCgi/Demo.pm',
                version => '1.148',
            },
            Quiq::Socket => {
                file => 'lib/Quiq/Socket.pm',
                version => '1.148',
            },
            Quiq::Sql => {
                file => 'lib/Quiq/Sql.pm',
                version => '1.148',
            },
            Quiq::SqlPlus => {
                file => 'lib/Quiq/SqlPlus.pm',
                version => '1.148',
            },
            Quiq::Ssh => {
                file => 'lib/Quiq/Ssh.pm',
                version => '1.148',
            },
            Quiq::Stacktrace => {
                file => 'lib/Quiq/Stacktrace.pm',
                version => '1.148',
            },
            Quiq::Stopwatch => {
                file => 'lib/Quiq/Stopwatch.pm',
                version => '1.148',
            },
            Quiq::Storable => {
                file => 'lib/Quiq/Storable.pm',
                version => '1.148',
            },
            Quiq::String => {
                file => 'lib/Quiq/String.pm',
                version => '1.148',
            },
            Quiq::System => {
                file => 'lib/Quiq/System.pm',
                version => '1.148',
            },
            Quiq::Table => {
                file => 'lib/Quiq/Table.pm',
                version => '1.148',
            },
            Quiq::TableRow => {
                file => 'lib/Quiq/TableRow.pm',
                version => '1.148',
            },
            Quiq::TeX::Code => {
                file => 'lib/Quiq/TeX/Code.pm',
                version => '1.148',
            },
            Quiq::TempDir => {
                file => 'lib/Quiq/TempDir.pm',
                version => '1.148',
            },
            Quiq::TempFile => {
                file => 'lib/Quiq/TempFile.pm',
                version => '1.148',
            },
            Quiq::Template => {
                file => 'lib/Quiq/Template.pm',
                version => '1.148',
            },
            Quiq::Terminal => {
                file => 'lib/Quiq/Terminal.pm',
                version => '1.148',
            },
            Quiq::Test::Class => {
                file => 'lib/Quiq/Test/Class.pm',
                version => '1.148',
            },
            Quiq::Test::Class::Method => {
                file => 'lib/Quiq/Test/Class/Method.pm',
                version => '1.148',
            },
            Quiq::Time => {
                file => 'lib/Quiq/Time.pm',
                version => '1.148',
            },
            Quiq::Time::RFC822 => {
                file => 'lib/Quiq/Time/RFC822.pm',
                version => '1.148',
            },
            Quiq::TimeLapse::Directory => {
                file => 'lib/Quiq/TimeLapse/Directory.pm',
                version => '1.148',
            },
            Quiq::TimeLapse::File => {
                file => 'lib/Quiq/TimeLapse/File.pm',
                version => '1.148',
            },
            Quiq::TimeLapse::Filename => {
                file => 'lib/Quiq/TimeLapse/Filename.pm',
                version => '1.148',
            },
            Quiq::TimeLapse::RangeDef => {
                file => 'lib/Quiq/TimeLapse/RangeDef.pm',
                version => '1.148',
            },
            Quiq::TimeLapse::Sequence => {
                file => 'lib/Quiq/TimeLapse/Sequence.pm',
                version => '1.148',
            },
            Quiq::Timeseries::Synchronizer => {
                file => 'lib/Quiq/Timeseries/Synchronizer.pm',
                version => '1.148',
            },
            Quiq::TreeFormatter => {
                file => 'lib/Quiq/TreeFormatter.pm',
                version => '1.148',
            },
            Quiq::Udl => {
                file => 'lib/Quiq/Udl.pm',
                version => '1.148',
            },
            Quiq::Unindent => {
                file => 'lib/Quiq/Unindent.pm',
                version => '1.148',
            },
            Quiq::Url => {
                file => 'lib/Quiq/Url.pm',
                version => '1.148',
            },
            Quiq::XTerm => {
                file => 'lib/Quiq/XTerm.pm',
                version => '1.148',
            },
            Quiq::Xml::LibXml => {
                file => 'lib/Quiq/Xml/LibXml.pm',
                version => '1.148',
            },
        },
    },
);

# eof
