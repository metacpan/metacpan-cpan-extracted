#include "../lib/test.h"
#include <regex>

#define TEST(name) TEST_CASE("compile-form: " name, "[compile-form]")

static std::pair<string, string> canonize(const string& str) {
    std::string s(str.c_str());
    std::regex re_boundary("; boundary=(-+\\w+)");
    std::smatch match;
    bool found = std::regex_search(s, match, re_boundary);
    assert(found);
    std::string boundary(match[1]);
    std::regex re(boundary);
    string r;
    std::regex_replace(std::back_inserter(r), s.begin(), s.end(),  re,  "-----------------------XXXXXXXXXXXXXXXXX");

    return {r, string(boundary.c_str())};
}

TEST("multipart/form-data (complete)") {
    std::srand(123);

    string str_sample =
        "POST / HTTP/1.1\r\n"
        "Content-Length: 232\r\n"
        "Content-Type: multipart/form-data; boundary=-----------------------YYYYYYYYYYYYYYYYY\r\n"
        "\r\n"
        "-------------------------YYYYYYYYYYYYYYYYY\r\n"
        "Content-Disposition: form-data; name=\"k1\"\r\n"
        "\r\n"
        "v1\r\n"
        "-------------------------YYYYYYYYYYYYYYYYY\r\n"
        "Content-Disposition: form-data; name=\"k2\"\r\n"
        "\r\n"
        "v2\r\n"
        "-------------------------YYYYYYYYYYYYYYYYY--\r\n";
    auto str = canonize(str_sample).first;

    SECTION("empty form -> no body is sent, method is still GET") {
        Request::Form form(Request::EncType::MULTIPART);
        auto req = Request::Builder().form(std::move(form)).build();
        CHECK(req->to_string() ==
            "GET / HTTP/1.1\r\n"
            "\r\n"
        );
    }

    SECTION("create simple form and serialize it") {
        Request::Form form(Request::EncType::MULTIPART);
        form.add("k1", "v1");
        form.add("k2", "v2");
        auto req = Request::Builder().form(std::move(form)).build();
        auto data = req->to_string();
        auto pair = canonize(data);
        REQUIRE(pair.first == str);
        auto boundary = pair.second;
    }

    SECTION("send a small file") {
        Request::Form form(Request::EncType::MULTIPART);
        form.add("k1", "v1", "sample.jpg", "image/jpeg");
        auto req = Request::Builder().form(std::move(form)).build();
        auto data = canonize(req->to_string()).first;

        std::srand(123);
        string sample_str = string(
                "POST / HTTP/1.1\r\n"
                "Content-Length: 188\r\n"
                "Content-Type: multipart/form-data; boundary=-----------------------FR7ODbhRMIR3XblaZ\r\n"
                "\r\n"
                "-------------------------FR7ODbhRMIR3XblaZ\r\n"
                "Content-Disposition: form-data; name=\"k1\"; filename=\"sample.jpg\"\r\n"
                "Content-Type: image/jpeg\r\n"
                "\r\n"
            ) + "v1\r\n"
            "-------------------------FR7ODbhRMIR3XblaZ--\r\n";
        auto sample = canonize(sample_str).first;

        CHECK(data == sample);
    }

    SECTION("uri query -> form") {
        Request::Form form(Request::EncType::MULTIPART);
        auto req = Request::Builder()
                .uri("/?k1=v1&k2=v2")
                .form(std::move(form))
                .build();
        auto data = req->to_string();
        auto pair = canonize(data);
        REQUIRE(pair.first == str);
    }

}

TEST("application/x-www-form-urlencoded") {
    Request::Form form(Request::EncType::URLENCODED);
    form.add("k1", "v11");
    form.add("k1", "v12");
    form.add("k2", "v2");

    SECTION("enrich query") {
        auto req = Request::Builder()
                .method(Request::Method::POST)
                .uri("/path?k3=v3&k4=v4")
                .form(std::move(form)).build();
        CHECK(req->to_string() ==
            "POST /path?k1=v11&k1=v12&k2=v2&k3=v3&k4=v4 HTTP/1.1\r\n"
             "Content-Length: 0\r\n"
            "\r\n"
        );
    }

    SECTION("empty uri case") {
        auto req = Request::Builder()
                .form(std::move(form)).build();
        CHECK(req->to_string() ==
            "GET /?k1=v11&k1=v12&k2=v2 HTTP/1.1\r\n"
            "\r\n"
        );
    }
}

template<typename String, typename Container>
string merge(String s, Container c) {
    for(auto& it:c) {
        s += string(it);
    }
    return s;
}

// content can be tested with http://ptsv2.com + netcat

TEST("multipart/form-data (streaming)") {
    auto req = Request::Builder().form_stream().build();
    SECTION("emtpy form") {
        auto data = req->to_string();
        data = merge(data, req->form_finish());
        CHECK(canonize(data).first ==
            "POST / HTTP/1.1\r\n"
            "Content-Type: multipart/form-data; boundary=-----------------------XXXXXXXXXXXXXXXXX\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "2e\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX--\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }

    SECTION("form with 1 embedded field") {
        auto data = req->to_string();
        data = merge(data, req->form_field("key", "value"));
        data = merge(data, req->form_finish());
        //std::cout << "zzz:\n" << data << "zzz\n";
        CHECK(canonize(data).first ==
            "POST / HTTP/1.1\r\n"
            "Content-Type: multipart/form-data; boundary=-----------------------XXXXXXXXXXXXXXXXX\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "61\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX\r\n"
            "Content-Disposition: form-data; name=\"key\"\r\n"
            "\r\n"
            "value"
            "\r\n\r\n"
            "2e\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX--\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }

    SECTION("form with 1 embedded file") {
        auto data = req->to_string();
        data = merge(data, req->form_field("key", "[pdf]", "cv.pdf", "application/pdf"));
        data = merge(data, req->form_finish());
        //std::cout << "zzz:\n" << data << "zzz\n";
        CHECK(canonize(data).first ==
            "POST / HTTP/1.1\r\n"
            "Content-Type: multipart/form-data; boundary=-----------------------XXXXXXXXXXXXXXXXX\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "93\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX\r\n"
            "Content-Disposition: form-data; name=\"key\"; filename=\"cv.pdf\"\r\n"
            "Content-Type: application/pdf\r\n"
            "\r\n"
            "[pdf]"
            "\r\n\r\n"
            "2e\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX--\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }

    SECTION("start streaming file") {
        auto data = req->to_string();
        data = merge(data, req->form_file("key", "cv.pdf", "application/pdf"));
        data = merge(data, req->form_data("[0123456789]"));
        data = merge(data, req->form_finish());
        //std::cout << "zzz:\n" << data << "zzz\n";
        CHECK(canonize(data).first ==
            "POST / HTTP/1.1\r\n"
            "Content-Type: multipart/form-data; boundary=-----------------------XXXXXXXXXXXXXXXXX\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "8c\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX\r\n"
            "Content-Disposition: form-data; name=\"key\"; filename=\"cv.pdf\"\r\n"
            "Content-Type: application/pdf\r\n"
            "\r\n"
            "\r\n"
            "c\r\n"
            "[0123456789]"
            "\r\n"
            "30\r\n"
            "\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX--\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }

    SECTION("start streaming file, then embed field") {
        //auto req = Request::Builder().uri("http://ptsv2.com/t/27ibp-1600433748/post").form_stream().build();
        auto data = req->to_string();
        data = merge(data, req->form_file("key", "cv.pdf", "application/pdf"));
        data = merge(data, req->form_data("[0123456789]"));
        data = merge(data, req->form_field("key2", "[pdf]"));
        data = merge(data, req->form_finish());
        //std::cout << "zzz:\n" << data << "zzz\n";
        CHECK(canonize(data).first ==
            "POST / HTTP/1.1\r\n"
            "Content-Type: multipart/form-data; boundary=-----------------------XXXXXXXXXXXXXXXXX\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "8c\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX\r\n"
            "Content-Disposition: form-data; name=\"key\"; filename=\"cv.pdf\"\r\n"
            "Content-Type: application/pdf\r\n"
            "\r\n"
            "\r\n"
            "c\r\n"
            "[0123456789]"
            "\r\n"
            "64\r\n"
            "\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX\r\n"
            "Content-Disposition: form-data; name=\"key2\"\r\n"
            "\r\n"
            "[pdf]\r\n\r\n"
            "30\r\n\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX--\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }

    SECTION("start streaming file, then embed field, gzip compression is ignored") {
        //auto req = Request::Builder().uri("/").form_stream()/* .compress(Compression::Type::GZIP) */ .build();
        auto req = Request::Builder().uri("/").form_stream().compress(Compression::Type::GZIP).build();
        auto data = req->to_string();
        data = merge(data, req->form_file("key", "cv.pdf", "application/pdf"));
        data = merge(data, req->form_data("[0123456789]"));
        data = merge(data, req->form_field("key2", "[pdf]"));
        data = merge(data, req->form_finish());
        CHECK(canonize(data).first ==
            "POST / HTTP/1.1\r\n"
            "Content-Type: multipart/form-data; boundary=-----------------------XXXXXXXXXXXXXXXXX\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "8c\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX\r\n"
            "Content-Disposition: form-data; name=\"key\"; filename=\"cv.pdf\"\r\n"
            "Content-Type: application/pdf\r\n"
            "\r\n"
            "\r\n"
            "c\r\n"
            "[0123456789]"
            "\r\n"
            "64\r\n"
            "\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX\r\n"
            "Content-Disposition: form-data; name=\"key2\"\r\n"
            "\r\n"
            "[pdf]\r\n\r\n"
            "30\r\n\r\n"
            "-------------------------XXXXXXXXXXXXXXXXX--\r\n"
            "\r\n"
            "0\r\n\r\n"
        );
    }
}
