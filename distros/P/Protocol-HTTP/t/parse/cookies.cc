#include "../lib/test.h"

#define TEST(name) TEST_CASE("parse-cookies: " name, "[parse-cookies]")

TEST("request single cookie") {
    RequestParser p;
    string raw =
        "GET / HTTP/1.1\r\n"
        "Cookie: key=value\r\n"
        "\r\n";

    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.state == State::done);
    CHECK(req->cookies.size() == 1);
    CHECK(req->cookies.get("key") == "value");
}

TEST("request multiple cookies") {
    RequestParser p;
    string raw = "GET / HTTP/1.1\r\n";

    SECTION("in single header") {
        raw += "Cookie: key=value; key2=value2\r\n";
    }
    SECTION("in multiple headers") {
        raw += "Cookie: key=value\r\n"
               "Cookie: key2=value2\r\n";
    }

    raw += "\r\n";

    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.state == State::done);
    CHECK(req->cookies.size() == 2);
    CHECK(req->cookies.get("key") == "value");
    CHECK(req->cookies.get("key2") == "value2");
}

TEST("response single cookie") {
    ResponseParser p;
    p.set_context_request(new Request());
    string raw =
        "HTTP/1.1 200 OK\r\n"
        "Set-Cookie: key=value; Domain=.crazypanda.ru; Path=/; Max-Age=999; Expires=Thu, 28 Nov 2019 18:43:59 GMT; Secure; HttpOnly; SameSite=Lax\r\n"
        "Content-Length: 0\r\n"
        "\r\n";

    auto result = p.parse(raw);
    auto res = result.response;
    CHECK(result.state == State::done);
    CHECK(res->cookies.size() == 1);
    REQUIRE(res->cookies.get("key"));
    auto coo = res->cookies.get("key").value();
    CHECK(coo.value() == "value");
    CHECK(coo.domain() == ".crazypanda.ru");
    CHECK(coo.path() == "/");
    CHECK(coo.max_age() == 999);
    REQUIRE(coo.expires());
    CHECK(coo.expires().value() == Date(2019, 11, 28, 18, 43, 59, 0, -1, panda::time::tzget("GMT")));
    CHECK(coo.secure());
    CHECK(coo.http_only());
    CHECK(coo.same_site() == Response::Cookie::SameSite::Lax);
}

TEST("response multiple cookies") {
    ResponseParser p;
    p.set_context_request(new Request());
    string raw =
        "HTTP/1.1 200 OK\r\n"
        "Set-Cookie: key=value; Domain=.crazypanda.ru; Path=/; Max-Age=999; Secure; HttpOnly; SameSite=None\r\n"
        "Set-Cookie: key2=value2; Domain=epta.ru; Path=/jopa; Max-Age=222; SameSite\r\n"
        "Content-Length: 0\r\n"
        "\r\n";

    auto result = p.parse(raw);
    auto res = result.response;
    CHECK(result.state == State::done);
    CHECK(res->cookies.size() == 2);

    REQUIRE(res->cookies.get("key"));
    auto coo = res->cookies.get("key").value();
    CHECK(coo.value() == "value");
    CHECK(coo.domain() == ".crazypanda.ru");
    CHECK(coo.path() == "/");
    CHECK(coo.max_age() == 999);
    CHECK(coo.secure());
    CHECK(coo.http_only());
    CHECK(coo.same_site() == Response::Cookie::SameSite::None);

    REQUIRE(res->cookies.get("key2"));
    coo = res->cookies.get("key2").value();
    CHECK(coo.value() == "value2");
    CHECK(coo.domain() == "epta.ru");
    CHECK(coo.path() == "/jopa");
    CHECK(coo.max_age() == 222);
    CHECK_FALSE(coo.secure());
    CHECK_FALSE(coo.http_only());
    CHECK(coo.same_site() == Response::Cookie::SameSite::Strict);

}
