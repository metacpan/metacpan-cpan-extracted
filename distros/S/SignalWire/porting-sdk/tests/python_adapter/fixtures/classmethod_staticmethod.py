"""Golden fixture: classmethod and staticmethod decorators.

The classmethod's first parameter is the class itself (kind=cls); the
staticmethod has no implicit receiver at all.
"""


class Builder:
    @classmethod
    def from_string(cls, source: str) -> "Builder":
        return cls()

    @staticmethod
    def parse_version(text: str) -> int:
        return 0
