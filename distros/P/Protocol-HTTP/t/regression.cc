#include "lib/test.h"
#include <set>
#include <fstream>
#include <string.h>
#include <dirent.h>
#include <sys/types.h>

#define TEST(name) TEST_CASE("regression: " name, "[regression]")

const string ROOT = "t/regression/";

inline std::set<string> read_directory (const string& name = ".") {
    DIR* dirp = opendir(name.c_str());
    struct dirent* dp;
    std::set<string> v;
    while ((dp = readdir(dirp)) != NULL) {
        if (!strcmp(dp->d_name, ".") || !strcmp(dp->d_name, "..")) continue;
        v.insert(string(dp->d_name, strlen(dp->d_name)));
    }
    closedir(dirp);
    return v;
}

TEST("additional final chunk before other chunks") {
    RequestParser p;
    string raw =
        "GET / HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "Connection: keep-alive\r\n"
        "\r\n"
        "0\r\n"
        "\r\n"
        "2\r\n"
        "12\r\n"
        "2\r\n"
        "34\r\n"
        "2\r\n"
        "56\r\n"
        "0\r\n"
        "\r\n"
    ;
    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.position == 75); //stoped at first final chunk
    CHECK_FALSE(result.error);
    CHECK(result.state == State::done);
    CHECK(req->body.to_string() == "");
}

TEST("response chunks #1") {
    ResponseParser p;
    RequestSP req = new Request();
    req->method_raw(Method::GET);
    p.set_context_request(req);

    std::vector<string> v = {
        "HTTP/1.1 200 OK\r\n"
        "Transfer-Encoding: chunked\r\n"
        "Connection: keep-alive\r\n"
        "\r\n",
        "4\r\n"
        "ans1\r\n",
        "0\r\n"
        "\r\n"
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 4\r\n"
        "Connection: close\r\n"
        "\r\n"
        "ans2"
    };

    auto result = p.parse_shift(v[0]);
    CHECK(result.state != State::done);
    CHECK(result.response->body.to_string() == "");
    CHECK_FALSE(v[0]);

    result = p.parse_shift(v[1]);
    CHECK(result.state != State::done);
    CHECK(result.response->body.to_string() == "ans1");
    CHECK_FALSE(v[1]);

    result = p.parse_shift(v[2]);
    CHECK(result.state == State::done);
    CHECK(result.response->body.to_string() == "ans1");
    CHECK(v[2][0] == 'H');

    p.set_context_request(req);
    result = p.parse_shift(v[2]);
    CHECK(result.state == State::done);
    CHECK_FALSE(result.error);
    CHECK(result.response->body.to_string() == "ans2");
    CHECK_FALSE(v[2]);
}

TEST("google response 0") {
    ResponseParser p;
    RequestSP req = new Request();
    req->method_raw(Method::GET);
    p.set_context_request(req);
    
    string raw =
        "HTTP/1.1 302 Found\r\n"
        "Cache-Control: private\r\n"
        "Content-Type: text/html; charset=UTF-8\r\n"
        "Referrer-Policy: no-referrer\r\n"
        "Location: http://www.google.ru/?gfe_rd=cr&dcr=0&ei=dlSVWsfRFMiG7gT1wK8Q\r\n"
        "Content-Length: 266\r\n"
        "Date: Tue, 27 Feb 2018 12:52:06 GMT\r\n"
        "\r\n"
        "<HTML><HEAD><meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\">\r\n"
        "<TITLE>302 Moved</TITLE></HEAD><BODY>\r\n"
        "<H1>302 Moved</H1>\r\n"
        "The document has moved\r\n"
        "<A HREF=\"http://www.google.ru/?gfe_rd=cr&amp;dcr=0&amp;ei=dlSVWsfRFMiG7gT1wK8Q\">here</A>.\r\n"
        "</BODY></HTML>\r\n";

    auto result = p.parse_shift(raw);
    CHECK(result.state == State::done);
    CHECK(result.response->http_version == 11);
}

TEST("google response 1") {
    ResponseParser p;
    RequestSP req = new Request();
    req->method_raw(Method::GET);
    p.set_context_request(req);
    
    ResponseParser::Result result;
    auto DIR = ROOT+"1";
    for (auto fname : read_directory(DIR)) {
        if (result.response) CHECK(result.state != State::done);
        std::ifstream file(DIR+"/"+fname, std::ios::binary);
        std::string str((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
        result = p.parse(string(str.c_str()));
    }

    CHECK(result.state == State::done);
    CHECK(result.response->http_version == 11);
}
