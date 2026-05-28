"""Golden fixture: simple positional parameters with primitive types."""


class Greeter:
    def greet(self, name: str, count: int) -> str:
        return name * count
