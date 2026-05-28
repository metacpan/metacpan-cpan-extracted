"""Golden fixture: Union[A, B] and PEP 604 ``A | B`` syntax."""

from typing import Union


class Coercer:
    def coerce(self, value: Union[str, int], fallback: float | bool) -> str:
        ...
